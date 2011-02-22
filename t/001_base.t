use Test::More tests => 2;
use strict;
use warnings;

use_ok 'Brocco';

chdir 't/';

diag("Deploying development schema..");
rename('brocco.db','brocco.db.old') if -f 'brocco.db';
qx{../bin/deploy_schema ../environments/development.yml};
ok(-f 'brocco.db') or BAIL_OUT("Need brocco.db to continue further testing");
