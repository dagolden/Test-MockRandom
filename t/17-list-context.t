# Test::MockRandom
use strict;

use Test::More tests => 6 ;

#--------------------------------------------------------------------------#
# Test package overriding via import to global
#--------------------------------------------------------------------------#

use Test::MockRandom qw( CORE::GLOBAL );
use lib qw( ./t );
use RandomList;

for ( __PACKAGE__, "SomeListPackage" ) {
    is( UNIVERSAL::can( $_, 'rand'), undef,
        "rand should not have been imported into $_" );
}
for (qw ( srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}

my $obj = SomeListPackage->new;
isa_ok ( $obj, 'SomeListPackage');
srand(.5);
# list_random(10) actually returns 5
isnt($obj->list_random(10), 0, 'testing $obj->list_random(10) != 0');
