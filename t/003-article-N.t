use Test::More;
use strict;
use warnings;

# the order is important
use Brocco;
BEGIN{ chdir 't/' }
use Dancer::Test;

route_exists          [ GET   => '/article/1' ], 'a route handler is defined for /article/1';
response_status_is    [ 'GET' => '/article/1' ], 200, 'response status is 200 for /article/1';
response_content_like [ GET   => '/article/1' ], qr{title>My first post \| Brocco \| Blog</title}, "title OK for GET";
response_content_like [ GET   => '/article/1' ], qr/owered by/, "has powered by";
response_content_like [ GET   => '/article/1' ], qr/This blog is written in/, "blog bio OK for GET";
response_content_like [ GET   => '/article/1' ], qr/Blog tags/, "blog tags OK for GET";
response_content_like [ GET   => '/article/1' ], qr/iled under/, "blog filed under OK for GET";
response_content_like [ GET   => '/article/1' ], qr{href="/article/tag/\w+}, "blog tags hrefs OK for GET";

route_exists          [ GET   => '/article/1/bogus-title' ], 'a route handler is defined for /article/1/bogus-title';
response_status_is    [ 'GET' => '/article/1/bogus-title' ], 200, 'response status is 200 for /article/1/bogus-title';
response_content_like [ GET   => '/article/1/bogus-title' ], qr{title>My first post \| Brocco \| Blog</title}, "title OK for GET";
response_content_like [ GET   => '/article/1/bogus-title' ], qr/owered by/, "has powered by";
response_content_like [ GET   => '/article/1/bogus-title' ], qr/This blog is written in/, "blog bio OK for GET";
response_content_like [ GET   => '/article/1/bogus-title' ], qr/Blog tags/, "blog tags OK for GET";
response_content_like [ GET   => '/article/1/bogus-title' ], qr/iled under/, "blog filed under OK for GET";
response_content_like [ GET   => '/article/1/bogus-title' ], qr{href="/article/tag/\w+}, "blog tags hrefs OK for GET";

route_exists [ GET => '/article/list' ], 'route exists /article/list';
route_exists [ GET => '/article/new' ],  'route exists /article/new';
route_exists [ GET => '/article/edit/1' ], 'route exists /article/edit/1';

## NOT LOGGED IN => These should redirect to /
sub redirected_to_login_ok
{
    my ($method,$path) = @_;
    my $response = dancer_response $method => $path;
    is($response->status, 302, "302 for $path");
    like($response->header('location'), qr{/login}, "Correct redirected to login URI for $path");
}

redirected_to_login_ok('GET','/article/list');
redirected_to_login_ok('GET','/article/new');
redirected_to_login_ok('POST','/article/new');
redirected_to_login_ok('GET','/article/edit/1');
redirected_to_login_ok('POST','/article/edit/1');
redirected_to_login_ok('POST','/article/preview_render');
redirected_to_login_ok('GET','/admin/bio');
redirected_to_login_ok('POST','/admin/bio');

done_testing;
