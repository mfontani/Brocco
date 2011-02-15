package Brocco::Schema::Result::ArticleTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Brocco::Schema::Result::ArticleTag

=cut

__PACKAGE__->table("article_tag");

=head1 ACCESSORS

=head2 tag_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 article_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "tag_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "article_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("tag_id", "article_id");

=head1 RELATIONS

=head2 tag

Type: belongs_to

Related object: L<Brocco::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "Brocco::Schema::Result::Tag",
  { id => "tag_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 article

Type: belongs_to

Related object: L<Brocco::Schema::Result::Article>

=cut

__PACKAGE__->belongs_to(
  "article",
  "Brocco::Schema::Result::Article",
  { id => "article_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-02-14 23:31:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vG8+BIDoOwArg4GgJuQL5Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
