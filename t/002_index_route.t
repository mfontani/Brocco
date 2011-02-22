use Test::More;
use strict;
use warnings;

# the order is important
use Brocco;
BEGIN{ chdir 't/' }
use Dancer::Test;

Brocco::set log => 'debug';

route_exists          [ GET   => '/' ], 'a route handler is defined for /';
response_status_is    [ 'GET' => '/' ], 200, 'response status is 200 for /';
response_content_like [ GET   => '/' ], qr{title>Brocco \| Blog</title}, "title OK for GET";
response_content_like [ GET   => '/' ], qr/owered by/, "has powered by";
response_content_like [ GET   => '/' ], qr/This blog is written in/, "blog bio OK for GET";
response_content_like [ GET   => '/' ], qr/Blog tags/, "blog tags OK for GET";
response_content_like [ GET   => '/' ], qr{href="/article/tag/\w+}, "blog tags hrefs OK for GET";

done_testing;
