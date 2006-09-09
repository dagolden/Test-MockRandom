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

use Test::MockRandom {
    rand   => [ { 'OverrideTest' => 'random' }, 'AnotherOverride' ],
    srand  => { 'OverrideTest' => 'seed' },
    oneish => __PACKAGE__ 
};                        

can_ok ('OverrideTest',    qw ( random seed ) );
can_ok ('AnotherOverride', qw ( rand ) );
can_ok (__PACKAGE__,       qw ( oneish ) );

OverrideTest::seed(.5, oneish() );
is (OverrideTest::random(), .5, 
        'testing OverrideTest::random()');
is (AnotherOverride::rand(), oneish(), 
        'testing AnotherOverride::rand()');


