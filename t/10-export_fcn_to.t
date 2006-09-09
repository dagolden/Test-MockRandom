#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Test::MockRandom  

use Test::More tests =>  5 ;
use Test::Exception;

#--------------------------------------------------------------------------#
# Test package overriding
#--------------------------------------------------------------------------#

use Test::MockRandom;

BEGIN {
    Test::MockRandom->export_rand_to( 'OverrideTest' );
    Test::MockRandom->export_srand_to( 'OverrideTest' );
    Test::MockRandom->export_oneish_to( 'OverrideTest' );
}

dies_ok { Test::MockRandom::export_rand_to( 'bogus' ) }
    "Dies when export_*_to not called as class function";
dies_ok { Test::MockRandom->export_rand_to() }
    "Dies when export_*_to not given an argument";
    
can_ok ('OverrideTest', qw ( rand srand oneish ));
OverrideTest::srand(.5, OverrideTest::oneish);
is (OverrideTest::rand(), .5, 
        'testing OverrideTest::srand(.5)');
is (OverrideTest::rand(), OverrideTest::oneish, 
        'testing OverrideTest::srand(OverrideTest::oneish)');


