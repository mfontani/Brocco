use Test::More;
use strict;
use warnings;

# the order is important
use Brocco;
BEGIN{ chdir 't/' }
use Dancer::Test;
use Data::Dumper;

Brocco::set log => 'debug';

# login
dancer_response POST => '/login' => { params => { user => 'admin', pass => 'Passw0rd', }};
# GET after login should give welcome
response_status_is    [ 'GET' => '/' ], 200, 'response status is 200 for /';
response_content_like [ GET   => '/' ], qr/Welcome admin/, "logged in OK for GET";
response_content_like [ GET   => '/' ], qr//, "logged in OK for GET";

my $response;

# There are two articles, each with a number of tags.

# the first dummy page should be listed under "stuff" and "meh"
$response = dancer_response GET => '/article/tag/stuff';
is( $response->status, 200, "200 for /article/tag/stuff" );
like( $response->{content}, qr#Articles tagged#, "Contains 'articles tagged'");
like( $response->{content}, qr#My first post#,   "Contains 'My first post'");
$response = dancer_response GET => '/article/tag/meh';
is( $response->status, 200, "200 for /article/tag/meh" );
like( $response->{content}, qr#Articles tagged#, "Contains 'articles tagged'");
like( $response->{content}, qr#My first post#,   "Contains 'My first post'");

$response = dancer_response GET => '/article/tag/xxx';
is( $response->status, 200, "200 for /article/tag/xxx" );

# TODO should have no articles there

done_testing;
