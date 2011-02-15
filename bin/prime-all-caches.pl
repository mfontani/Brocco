#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use BlogPan::Schema;
use Time::HiRes qw/gettimeofday tv_interval/;

sub timethis
{
    my $what    = shift;
    my $coderef = shift;
    warn "$what\n";
    my $t0 = [gettimeofday];
    $coderef->();
    warn "Elapsed: " . tv_interval($t0,[gettimeofday]);
}

my $base_url = shift
    or die "Need base URL\n";

my $n_articles = shift
    or die "Need also number of articles\n";

timethis("Base url $base_url", sub { qx{curl $base_url >/dev/null 2>&1} } );

for my $id (1..$n_articles)
{
    timethis("$base_url/article/id/$id", sub { qx{curl $base_url/article/id/$id >/dev/null 2>&1} } );
    sleep 0.5;
}

