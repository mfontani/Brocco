# Brocco

My blog engine, written in Perl, using the Dancer framework

From the [Leghornese][1] "Bròcco nòte", meaning "notepad".
Not from the Italian "brocco", meaning "Nag", a horse of low quality.

## Installation

This assumes you're using a separate user on your machine, and
starman to run the webapp.

Create the new user, su to it

    $ sudo su -c "adduser --disabled-password --gecos 'Brocco' brocco"
    $ sudo su - brocco

Install cpanm

    $ curl -O http://xrl.us/cpanm > cpanm
    $ chmod +x cpanm
    $ # you want local modules in ~/perl5
    $ ./cpanm local::lib
    $ echo 'eval $(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)' >> ~/.bashrc
    $ eval $(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)
    $ # upgrade cpanminus
    $ ./cpanm App::cpanminus

Install Brocco's prerequisites

    $ cpanm Dancer Text::MultiMarkdown DBIx::Class \
        Dancer::Plugin::DBIC Dancer::Plugin::FlashMessage \
        Cache::Memcached::Fast Date::Calc \
        Dancer::Session::Cookie Text::Xslate \
        Dancer::Template::Xslate Starman \
        Digest::SHA
    # output...

If you want to modify the db's schema and update its modules,
install also this:

    $ cpanm DBIx::Class::Schema::Loader

Use mysql and create a database, 'brocco':

    $ mysql -uroot -pPASS 'create database brocco default character set=utf8;'

Populate the schema:

    $ bin/restore-sql brocco root PASS

Optionally create a new database user, grant it privileges on all the `brocco`
tables, and amend the `config.yml` to have the webapp use that user to connect
to the database.

Change `config.yml` to suit your needs. The comments should help you.
Change also the configs under `environment/`, both for development and
production.

# Launch the tests

Once the database schema has been restored, you can launch the tests:

    prove -vl t/

They should all pass. Nag me (see the Issues tab on Github) if they don't.

# Launch a development server

    $ bin/app.pl --port 12345 --restart

# Login and logout

You can now login at http://localhost:12345/login. The credentials are:

    username: admin
    password: Passw0rd

You can change your nickname, name and biography by clicking on "Your Bio"
once logged in.

Conversely, just point your browser to `/logout` to log out. You will be logged
out after 1 hour.

# Personalisation

You may want to change `views/about-blog.tt` to show something specific for
your blog. It's just HTML.

The `views/sidebar-links.tt` can also be edited, and will display a number of
links or adverts on the right hand side of the blog.

There is currently no facility to manage usernames; you can simply run the
following SQL to change the admin's username to mickey:

    mysql -uroot -pPASSWORD brocco \
        -e 'UPDATE brocco.author SET username="mickey" WHERE username="admin"'

# New blog entry (article)

Click on the "Post a new article" link. You can use MultiMarkdown on the entry's
body. Choose a good title and create tags for the post, separated by commas.
Tags will be automatically created on the database and the various caches
invalidated.

You may want to use the `bin/prime-all-caches.pl` script after having restarted
the blog server, to cache some of the articles.

Remember to set the article as "live", or it will not appear on your blog :)

# Deploy using starman (and tmux?)

    $ tmux -2 -u
    $ tmux rename-session brocco
    $ starman --listen :4000 -MFindBin bin/app.pl
    $ # detach from tmux via CTRL+b d

# Change your webserver's config

An example using lighttpd; you will need the right modules like `mod_proxy`:

    $HTTP["host"] =~ "^blog\.example\.com$" {
        proxy.server = ( "" => (("host" => "127.0.0.1","port" => "4000")))
    }

# Nice to haves

You may want to use memcached. Simply change the config to point it
to the right memcached server(s).

You may want to serve static javascript and css from another domain.
Simply change the `cdn` configuration variable to poin to the web
server which is able to serve these static files.

# Problems?

Please open an issue on the Github "issues" tab.

[1]: http://en.wikipedia.org/wiki/Leghorn#Dialect
