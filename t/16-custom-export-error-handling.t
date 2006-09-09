#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Test::MockRandom  

use Test::More tests =>  1 ;
use Test::Exception;

#--------------------------------------------------------------------------#
# Test package overriding
#--------------------------------------------------------------------------#

dies_ok 
    { 
        require Test::MockRandom;
        Test::MockRandom->import( {
            bogus   => [ { 'OverrideTest' => 'random' }, 'AnotherOverride' ],
        });
    } " Does custom import spec croak on unrecognized symbol?";

