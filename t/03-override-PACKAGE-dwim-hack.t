# Test::MockRandom  
use strict;

use Test::More tests => 3;

#--------------------------------------------------------------------------#
# Test package overriding via import
#--------------------------------------------------------------------------#

use Test::MockRandom qw( __PACKAGE__ );

for (qw ( rand srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}
