use Test::More;
use strict;
use warnings;

# the order is important
use Brocco;
BEGIN{ chdir 't/' }
use Dancer::Test;
use Data::Dumper;

route_exists          [ GET   => '/login' ], 'a route handler is defined for /login';
response_status_is    [ 'GET' => '/login' ], 200, 'response status is 200 for /login';
response_content_like [ GET   => '/login' ], qr{title>Brocco | Blog</title}, "title OK for GET";
response_content_like [ GET   => '/login' ], qr/Log in/, "has Log in for GET";
response_content_like [ GET   => '/login' ], qr/Login/, "has Login for GET";

my $response;

# GET /login?failed=1
$response = dancer_response GET => '/login' => { params => { failed => 1 } };
is($response->status, 200, '200 for /login?failed=1');
like($response->{content}, qr/your login attempt failed/, "message OK for login failed");

# POST login, no params
$response = dancer_response POST => '/login';
is($response->status, 302, '302 for no data');
like($response->header('location'), qr{/login\?failed=1}, 'Correct failed login URI');

# POST login, wrong user
$response = dancer_response POST => '/login' => { params => { user => 'administrator', pass => 'password', }};
is($response->status, 302, '302 for invalid user');
like($response->header('location'), qr{/login\?failed=1}, 'Correct failed login URI');

# POST login, ok user wrong password
$response = dancer_response POST => '/login' => { params => { user => 'admin', pass => 'password', }};
is($response->status, 302, '302 for ok user wrong password');
like($response->header('location'), qr{/login\?failed=1}, 'Correct failed login URI');

# POST login, ok user ok password
$response = dancer_response POST => '/login' => { params => { user => 'admin', pass => 'Passw0rd', }};
is($response->status, 302, '302 for ok user ok password');
like($response->header('location'), qr{localhost/$}, 'Correct OK login URI');

# TODO test cookie is given?!

# GET after login should give welcome
$response = dancer_response GET => '/';
is($response->status, 200, '200 for / after login');
like($response->{content}, qr/Welcome admin/, "welcome OK for login ok");
like($response->{content}, qr/Successfully logged in/, "flash OK for login ok");

# Second GET should have no flash
$response = dancer_response GET => '/';
is($response->status, 200, '200 for / after login');
like($response->{content}, qr/Welcome admin/, "welcome OK for second GET after login ok");
unlike($response->{content}, qr/Successfully logged in/, "no flash for second GET after login ok");

# Logout
$response = dancer_response GET => '/logout';
is($response->status, 302, '302 for /logout after login');
like($response->header('location'), qr{localhost/$}, 'Correct OK logout URI');
$response = dancer_response GET => '/';
is($response->status, 200, '200 for / after logout');
unlike($response->{content}, qr/Welcome admin/, "No welcome OK for GET after logout ok");
like($response->{content}, qr/Successfully logged out/, "flash for GET after logout ok");
$response = dancer_response GET => '/';
is($response->status, 200, '200 for / after logout');
unlike($response->{content}, qr/Welcome admin/, "No welcome OK for second GET after logout ok");
unlike($response->{content}, qr/Successfully logged out/, "no flash for second GET after logout ok");

done_testing;
