package Brocco::Schema::Result::Article;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Brocco::Schema::Result::Article

=cut

__PACKAGE__->table("article");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 author_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 published

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 status

  data_type: 'enum'
  default_value: 'draft'
  extra: {list => ["draft","archived","live"]}
  is_nullable: 1

=head2 title

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 512

=head2 description

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 512

=head2 body

  data_type: 'blob'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "author_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "published",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "status",
  {
    data_type => "enum",
    default_value => "draft",
    extra => { list => ["draft", "archived", "live"] },
    is_nullable => 1,
  },
  "title",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 512 },
  "description",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 512 },
  "body",
  { data_type => "blob", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 author

Type: belongs_to

Related object: L<Brocco::Schema::Result::Author>

=cut

__PACKAGE__->belongs_to(
  "author",
  "Brocco::Schema::Result::Author",
  { id => "author_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 article_tags

Type: has_many

Related object: L<Brocco::Schema::Result::ArticleTag>

=cut

__PACKAGE__->has_many(
  "article_tags",
  "Brocco::Schema::Result::ArticleTag",
  { "foreign.article_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-02-14 23:31:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gZQBSkZtwjIKk7o/93CeTg

sub nice_title
{
    my $self = shift;
    my $title = $self->title;
    $title =~ s/[^a-z0-9-]/-/gi;
    return $title;
}

sub _markdown_to_html
{
    my $self = shift;
    eval "require Text::MultiMarkdown";
    return Text::MultiMarkdown::markdown(shift);
}

sub excerpt_html
{
    my $self = shift;
    my ($teaser,$rest) = split(/\[cut\]/, $self->body);
    return $rest
        ? $self->_markdown_to_html($teaser)
        : substr( $self->_markdown_to_html( $self->body ), 0, 200)
    ;
}

sub body_html
{
    my $self = shift;
    my $body = $self->body;
    $body =~ s/\[cut\]//;
    return $self->_markdown_to_html($body);
}

sub as_hashref {
    my $self   = shift;
    my $author = $self->author;
    my @tags;
    for my $tag ( $self->article_tags )
    {
        push @tags, { id => $tag->tag->id, name => $tag->tag->name };
    }
    return {
        ( map { $_ => $self->$_ }
              qw/id author_id created published updated status title description body/ ),
          nice_title   => $self->nice_title,
          tags         => \@tags,
          excerpt_html => $self->excerpt_html,
          body_html    => $self->body_html,
          author => { ( map { $_ => $author->$_ } qw/id nickname status name username bio/ ), },
    }
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
