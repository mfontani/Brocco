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

# Admin posts a draft article on dancing squirrels

# First they preview it...
$response = dancer_response POST => '/article/preview_render' => {
    params => {
        title => 'Dancing Squirrels',
        tags  => 'peta, dancer, squirrels',
        text  => 'I have seen squirrels dance, with mooses. True story.'
    }
};
is( $response->status, 200, "200 for /article/preview_render" );
like( $response->{content}, qr/Dancing Squirrels/,    "Contains the title" );
like( $response->{content}, qr#/tag/peta#,            "Contains the peta tag link" );
like( $response->{content}, qr#/tag/dancer#,          "Contains the dancer tag link" );
like( $response->{content}, qr#/tag/squirrels#,       "Contains the squirrels tag link" );
like( $response->{content}, qr/seen squirrels dance/, "Contains the text" );

# Then they post it as draft...
$response = dancer_response POST => '/article/new' => {
    params => {
        status      => 'draft',
        title       => 'Dancing Squirrels',
        tags        => 'peta, dancer, squirrels',
        description => 'Squirreles dancing everywhere!',
        body        => 'I have seen squirrels dance, with mooses. True story.'
    }
};
is($response->status, 302, '302 for /article/new after POST to new');
my $new_article_id;
$new_article_id = $1 if ( $response->header('location') =~ m#/article/edit/(\d+)# );
ok(defined $new_article_id, 'redirected to edit the new article');

# The article should not be live, and the tags not shown
$response = dancer_response GET => '/';
like($response->{content}, qr/Welcome admin/, "welcome OK");
unlike($response->{content}, qr/Dancing Squirrels/, "No Dancing Squirrels on homepage");
unlike($response->{content}, qr/peta/, "No peta tag on homepage");
unlike($response->{content}, qr/squirrels/, "No squirrels on homepage");

# Go back to the article list...
$response = dancer_response GET => '/article/list';
is($response->status, 200, '200 for /article/list after login');
like($response->{content}, qr/Welcome admin/, "welcome OK for article list");
like($response->{content}, qr/All Articles/, "all articles OK for article list");
like($response->{content}, qr/Dancing Squirrels/, "There are Dancing Squirrels on list");
like($response->{content}, qr/peta/, "peta tag on article list");
like($response->{content}, qr/squirrels/, "squirrels on article list");

# Go back to edit the article
$response = dancer_response GET => '/article/edit/' . $new_article_id;
is($response->status, 200, '200 for /article/edit/NN after login');
like($response->{content}, qr/Welcome admin/, "welcome OK");
like($response->{content}, qr/Dancing Squirrels/, "There are Dancing Squirrels on edit page");
like($response->{content}, qr/peta/, "peta tag on article edit page");
like($response->{content}, qr/squirrels/, "squirrels on article edit page");

# Make it live! LIVE DANCING ENSUES
$response = dancer_response POST => '/article/edit/' . $new_article_id => {
    params => {
        status      => 'live',
        title       => 'Dancing Squirrels',
        tags        => 'peta, dancer, squirrels',
        description => 'Squirreles dancing everywhere!',
        body        => 'I have seen squirrels dance, with mooses. True story.',
        submit      => 1,
    }
};
is($response->status, 302, '302 for /article/edit/ID after POST to edit');
like($response->header('location'), qr#/article/edit/\d+#, "Redirected to edit");

# The article should be live, and the tags shown
$response = dancer_response GET => '/';
like($response->{content}, qr/Welcome admin/, "welcome OK");
like($response->{content}, qr/Dancing Squirrels/, "Dancing Squirrels on homepage");
like($response->{content}, qr/peta/, "peta tag on homepage");
like($response->{content}, qr/squirrels/, "squirrels on homepage");
like($response->{content}, qr/I have seen squirrels dance/, "have seen squirrels dance on homepage");

# Oh wait, I didn't want to post that!!!
$response = dancer_response GET => '/article/edit/' . $new_article_id;
is($response->status, 200, '200 for /article/edit/NN after login');
like($response->{content}, qr/Welcome admin/, "welcome OK");
like($response->{content}, qr/Dancing Squirrels/, "There are Dancing Squirrels on edit page");
like($response->{content}, qr/peta/, "peta tag on article edit page");
like($response->{content}, qr/squirrels/, "squirrels on article edit page");

# Quick, REMOVE ALL TRACES OF DANCING SQUIRRELS. And mooses.
$response = dancer_response POST => '/article/edit/' . $new_article_id => {
    params => {
        status      => 'archived',
        title       => 'Dancing Squirrels',
        tags        => 'peta, dancer, squirrels',
        description => 'Squirreles dancing everywhere!',
        body        => 'I have seen squirrels dance, with mooses. True story.',
        submit      => 1,
    }
};
is($response->status, 302, '302 for /article/edit/ID after POST to edit');
like($response->header('location'), qr#/article/edit/\d+#, "Redirected to edit");

# The article should not be live, and the tags not shown
$response = dancer_response GET => '/';
like($response->{content}, qr/Welcome admin/, "welcome OK");
unlike($response->{content}, qr/Dancing Squirrels/, "No more Dancing Squirrels on homepage");
unlike($response->{content}, qr/peta/, "No more peta tag on homepage");
unlike($response->{content}, qr/squirrels/, "No more squirrels on homepage");

# Go back to the article list...
$response = dancer_response GET => '/article/list';
is($response->status, 200, '200 for /article/list after login');
like($response->{content}, qr/Welcome admin/, "welcome OK for article list");
like($response->{content}, qr/All Articles/, "all articles OK for article list");
like($response->{content}, qr/Dancing Squirrels/, "There are Dancing Squirrels on list");
like($response->{content}, qr/peta/, "peta tag on article list");
like($response->{content}, qr/squirrels/, "squirrels on article list");

done_testing;
