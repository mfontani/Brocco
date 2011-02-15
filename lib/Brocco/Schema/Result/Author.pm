package Brocco::Schema::Result::Author;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Brocco::Schema::Result::Author

=cut

__PACKAGE__->table("author");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 nickname

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 status

  data_type: 'enum'
  default_value: 'archived'
  extra: {list => ["archived","live"]}
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 username

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 password

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 0
  size: 40

=head2 bio

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "nickname",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "status",
  {
    data_type => "enum",
    default_value => "archived",
    extra => { list => ["archived", "live"] },
    is_nullable => 1,
  },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "username",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "password",
  { data_type => "char", default_value => "", is_nullable => 0, size => 40 },
  "bio",
  { data_type => "blob", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 articles

Type: has_many

Related object: L<Brocco::Schema::Result::Article>

=cut

__PACKAGE__->has_many(
  "articles",
  "Brocco::Schema::Result::Article",
  { "foreign.author_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07006 @ 2011-02-14 23:31:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Lu7NMUSAL++FxlQMtO0WfQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
