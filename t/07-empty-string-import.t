#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Testing Test::MockRandom  

use Test::More tests =>  7 ;
use Test::Exception;

use Test::MockRandom '';
my @fcns = qw( 
    rand 
    srand 
    oneish 
    export_rand_to 
    export_srand_to
    export_oneish_to
);

can_ok( 'Test::MockRandom', @fcns );
for my $fcn ( @fcns ) {
    ok( ! UNIVERSAL::can( __PACKAGE__, $fcn), 
        "confirming that $fcn wasn't imported by default");
}

