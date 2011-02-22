use Test::More;
use strict;
use warnings;

# the order is important
use Brocco;
BEGIN{ chdir 't/' }
use Dancer::Test;
use Data::Dumper;

# login
dancer_response POST => '/login' => { params => { user => 'admin', pass => 'Passw0rd', }};
# GET after login should give welcome
response_status_is    [ 'GET' => '/' ], 200, 'response status is 200 for /';
response_content_like [ GET   => '/' ], qr/Welcome admin/, "logged in OK for GET";
response_content_like [ GET   => '/' ], qr//, "logged in OK for GET";

my $response;

# Admin can list articles
$response = dancer_response GET => '/article/list';
is($response->status, 200, '200 for /article/list after login');
like($response->{content}, qr/Welcome admin/, "welcome OK for second GET after login ok");
like($response->{content}, qr/All Articles/, "all articles OK for second GET after login ok");
like($response->{content}, qr/ould you want/, "would you want OK for second GET after login ok");

# Admin can GET form for new article
$response = dancer_response GET => '/article/new';
is($response->status, 200, '200 for /article/new after login');
like($response->{content}, qr/Welcome admin/, "welcome OK for second GET after login ok");
like($response->{content}, qr/Post a new article/, "post new article OK for second GET after login ok");

# Admin can GET form for editing bio
$response = dancer_response GET => '/admin/bio';
is($response->status, 200, '200 for /admin/bio after login');
like($response->{content}, qr/Welcome admin/, "welcome OK for second GET after login ok");
like($response->{content}, qr/Your information/, "has your information OK for second GET after login ok");


done_testing;
