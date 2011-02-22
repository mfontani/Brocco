package Brocco;

# vim: set foldmethod=marker :
use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashMessage;
use Cache::Memcached::Fast;
use Digest::SHA;
use Text::MultiMarkdown;

use Date::Calc qw/Today_and_Now/;

our $VERSION = '0.3';

our $memd = Cache::Memcached::Fast->new(
    {
        %{    config->{plugins}->{Memcached}
            ? config->{plugins}->{Memcached}
            : {
                servers   => ['127.0.0.1:11211'],
                namespace => 'brocco',
            }
          }
    }
);

our $default_cache_for = config->{brocco}->{cache_for};

sub valid_session {    # {{{
    return unless session->{username};
    return unless session->{logged_in_at};

    #debug( "Username " . session->{username} . " logged in at " . session->{logged_in_at} );
    return unless session->{logged_in_at} > ( time - 3600 );
    my ($author) = schema->resultset('Author')->search( { username => session->{username} } )->all;
    return unless $author;
    return unless $author->status eq 'live';
    return $author;
}    # }}}

## Hook to show tag cloud on all pages
before_template sub {    # {{{
    my $tokens = shift;
    $tokens->{tag_cloud} = do {
        my $_tag_cloud = $memd->get('tag_cloud');
        if ( !$_tag_cloud ) {

            #debug("Caching tag cloud..");
            $_tag_cloud = [
                schema->resultset('Tag')->search(
                    { 'article.status' => 'live', },
                    {
                        join     => { 'article_tags', 'article' },
                        distinct => 1,
                        '+select' => [ { count => 'article_id', -as => 'cnt' } ],
                        '+as'     => [qw/num_articles/],
                        order_by => { -desc => 'cnt' },
                    }
                  )->all
            ];
            $memd->set( 'tag_cloud', $_tag_cloud, $default_cache_for );

            #} else {
            #    debug("tag cloud was cached");
        }
        $_tag_cloud;
    };
    my $author = valid_session();
    $tokens->{flash_message}    = flash('message');
    $tokens->{session_username} = $author->username if $author;
    $tokens->{brocco}           = { %{ config->{brocco} }, version => $VERSION };
};    # }}}

## User routes:

get '/' => sub {    # {{{

    my $latest_articles = $memd->get('latest_10_articles');
    if ($latest_articles) {

        #debug("latest articles list was cached");
    } else {

        #debug("Gathering and caching articles list");
        my @latest_articles = schema->resultset('Article')->search(
            { status => 'live', },
            {
                order_by => { -desc => 'published' },
                rows     => 10,
            }
        )->all;
        $latest_articles = [ map { $_->as_hashref } @latest_articles ];
        $memd->set( 'latest_10_articles', $latest_articles, $default_cache_for );
    }
    return template index => { articles => $latest_articles };
};    # }}}

get '/article/tag/:tag' => sub {    # {{{

    my $articles_by_tag = $memd->get("bytag-" . params->{tag});
    if (!$articles_by_tag) {

        $articles_by_tag = [ schema->resultset('Article')->search(
            {
                'status'   => 'live',
                'tag.name' => params->{tag},
            },
            {
                join     => { 'article_tags', 'tag' },
                distinct => 1,
                '+select' => [ { count => 'article_id', -as => 'cnt' } ],
                '+as'     => [qw/num_articles/],
                order_by => { -desc => 'cnt' },
            }
          )->all
        ];
        if ($articles_by_tag) {

            $articles_by_tag = [ map $_->as_hashref, @$articles_by_tag ];
            $memd->set( "bytag-" . params->{tag}, $articles_by_tag, $default_cache_for );

            #} else {
            #    debug("No such article id $id -- not cached");
        }
    # } else {
    #    debug("Got cached article id $id");
    }

    #debug("Have " . scalar @$articles_by_tag . " articles tagged " . params->{tag});

    return template articles_by_tag => { tag => params->{tag}, articles_by_tag => $articles_by_tag };
};    # }}}

get qr{^/article/(\d+)(?:/.*)?$} => sub {    # {{{

    my ($id) = splat;

    my $article = $memd->get("article-$id");
    if (!$article) {
        my $art = schema->resultset('Article')->find($id);
        if ($art) {

            #debug("Caching article id $id");
            $article = $art->as_hashref;
            $memd->set( "article-$id", $article, $default_cache_for );

            #} else {
            #    debug("No such article id $id -- not cached");
        }
    # } else {
    #    debug("Got cached article id $id");
    }

    return template article => { article => $article };
};    # }}}


## Admin routes:

### Logging in / out

get '/login' => sub {    # {{{
    session->destroy unless valid_session;
    return template 'login', { path => vars->{requested_path}, failed => params->{failed} };
};    # }}}

post '/login' => sub {    # {{{
    unless ( params and params->{user} and params->{pass} ) {
        session->destroy;
        return redirect '/login?failed=1';
    }
    my @author = schema->resultset('Author')->search(
        {
            status   => 'live',
            username => params->{user},
            password => Digest::SHA::sha1_hex( params->{pass} ),
        }
    );
    if (@author) {

        #debug( "User " . params->{user} . " successfully logged in" );
        session username     => params->{user};
        session logged_in_at => time;
        flash message        => 'Successfully logged in';
        return redirect '/';
    }

    #debug( "BAD attempt at logging in " . params->{user} );
    session->destroy;
    return redirect '/login?failed=1';
};    # }}}

get '/logout' => sub {    # {{{
    session->destroy;
    flash message => 'Successfully logged out';
    return redirect '/';
};    # }}}

get '/admin' => sub {    # {{{
    return redirect '/';
    return template 'admin';
};    # }}}

### Other administrative routes

get '/admin/bio' => sub {    # {{{
    my $author = valid_session;
    return redirect '/login' if !$author;
    return template 'admin-bio.tt' => { author => $author };
};    # }}}

post '/admin/bio' => sub {    # {{{
    my $author = valid_session;
    return redirect '/login' if !$author;

    return template 'admin-bio.tt' => { author => $author } unless params->{save};

    my @changes;
    for (qw/nickname name bio/) {
        next if $author->$_ eq params->{$_};
        push @changes, $_;
        $author->$_( params->{$_} );
    }
    if (params->{password} and length params->{password}) {
        push @changes, 'password';
        $author->password( Digest::SHA::sha1_hex( params->{password} ) );
    }
    $author->update if @changes;

    if (@changes) {

        ## expire caches for all articles by the author
        my @articles_ids_by_author =
          map { $_->id }
          schema->resultset('Article')
          ->search( { author_id => $author->id }, { columns => qw/id/ } )->all;
        $memd->delete_multi( map { "article-$_" } @articles_ids_by_author );

        ## expire cache for articles list
        $memd->delete('latest_10_articles');
    }

    flash message => "Updated: @changes" if @changes;

    return template 'admin-bio.tt' => { author => $author };
};    # }}}

get '/article/list' => sub {    # {{{
    my $author = valid_session();
    return redirect '/login' if !$author;

    my @articles = map { $_->as_hashref } schema->resultset('Article')->all;
    return template article_list => { articles => \@articles };
};    # }}}

get '/article/edit/:id' => sub {    # {{{
    my $author = valid_session;
    return redirect '/login' if !$author;

    my $article = schema->resultset('Article')->find( params->{id} );
    return template article_edit => { article => $article->as_hashref };
};    # }}}

post '/article/edit/:id' => sub {    # {{{
    my $author = valid_session;
    return redirect '/login' if !$author;

    my $article = schema->resultset('Article')->find( params->{id} );
    return redirect '/' unless $article;
    return template article_edit => { article => $article } unless params->{submit};

    return template article_edit => { article => $article }
      unless scalar grep { params->{status} eq $_ } qw/draft archived live/;

    my $changes = 0;
    my $published = ( $article->status ne 'live' and params->{$_} eq 'live' );
    for (qw/status title description body/) {
        next if $article->$_ eq params->{$_};
        $changes++;
        $article->$_( params->{$_} );
    }
    $article->published( sprintf( "%04d-%02d-%02d %02d:%02d:%02d", Today_and_Now() ) )
      if $published;
    $article->updated( sprintf( "%04d-%02d-%02d %02d:%02d:%02d", Today_and_Now() ) ) if $changes;
    $article->update if $changes;

    my @old_tags =  map { $_->tag->name } $article->article_tags;
    $_->delete for $article->article_tags;
    my @new_tags = ( split( /,\s*/, params->{tags} ) );
    my @tag_ids = do {
        my @tmp;
        for my $tag (@new_tags) {
            $tag =~ s/^\s*//g;
            $tag =~ s/\s*$//g;
            $tag =~ s/(\s)\s+/$1/g;
            my $db_tag = schema->resultset('Tag')->find( { name => lc $tag } );
            if ( !$db_tag ) {
                $db_tag = schema->resultset('Tag')->new( { name => lc $tag } );
                $db_tag->insert;
            }
            push @tmp, $db_tag;
        }
        map { $_->id } @tmp;
    };
    schema->populate( 'ArticleTag',
        [ [ 'article_id', 'tag_id' ], map { [ $article->id, $_ ] } @tag_ids ] );

    $memd->delete_multi( qw/tag_cloud latest_10_articles/, "article-" . $article->id, map { "bytag-$_" } (@old_tags,@new_tags));

    return redirect '/article/edit/' . $article->id;
};    # }}}

get '/article/new' => sub {    # {{{
    my $author = valid_session;
    return redirect '/login' if !$author;
    return template article_edit => {};
};    # }}}

post '/article/new' => sub {    # {{{
    my $author = valid_session;
    return redirect '/login' unless $author;

    my $article = schema->resultset('Article')->new(
        {
            ( map { $_ => params->{$_} } (qw/status title description body/) ),
            author_id => $author->id,
            created   => sprintf( "%04d-%02d-%02d %02d:%02d:%02d", Today_and_Now() ),
            updated   => sprintf( "%04d-%02d-%02d %02d:%02d:%02d", Today_and_Now() ),
            (
                params->{status} eq 'live'
                ? ( published => sprintf( "%04d-%02d-%02d %02d:%02d:%02d", Today_and_Now() ), )
                : ()
            ),
        }
    );
    $article->insert;

    my @new_tags = ( split( /,\s*/, params->{tags} ) );
    my @tag_ids = do {
        my @tmp;
        for my $tag (@new_tags) {
            $tag =~ s/^\s*//g;
            $tag =~ s/\s*$//g;
            $tag =~ s/(\s)\s+/$1/g;
            my $db_tag = schema->resultset('Tag')->find( { name => lc $tag } );
            if ( !$db_tag ) {
                $db_tag = schema->resultset('Tag')->new( { name => lc $tag } );
                $db_tag->insert;
            }
            push @tmp, $db_tag;
        }
        map { $_->id } @tmp;
    };
    schema->populate( 'ArticleTag',
        [ [ 'article_id', 'tag_id' ], map { [ $article->id, $_ ] } @tag_ids ] );

    $memd->delete_multi( qw/tag_cloud latest_10_articles/, "article-" . $article->id, map { "bytag-$_" } @new_tags);

    flash message => 'Article created';
    return redirect '/article/edit/' . $article->id;
};    # }}}

post '/article/preview_render' => sub {    # {{{
    my $author = valid_session;
    return redirect '/login' if !$author;

    my $body_html = params->{text};
    $body_html =~ s/\n\[cut\]//g;
    $body_html = Text::MultiMarkdown::markdown($body_html);
    return template
      article => {
        article => {
            author => $author,
            title  => params->{title},
            tags   => [ map { name => $_ }, split( /,\s*/, params->{tags} ) ],
            published => sprintf( "%04d-%02d-%02d %02d:%02d:%02d", Today_and_Now() ),
            body_html => $body_html,
        },
      },
      { layout => undef };
};    # }}}

true;
