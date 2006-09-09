#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Test::MockRandom  

use Test::More tests => 3;
use Test::Exception;

#--------------------------------------------------------------------------#
# Test package overriding via import
#--------------------------------------------------------------------------#

use Test::MockRandom qw( __PACKAGE__ );

for (qw ( rand srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}
