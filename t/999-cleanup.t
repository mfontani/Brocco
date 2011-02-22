use Test::More tests => 2;
use strict;
use warnings;

chdir 't/';

ok(-f 'brocco.db');

unlink 'brocco.db';

ok(!-f 'brocco.db');
