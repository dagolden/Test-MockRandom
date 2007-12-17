package Test::MockRandom;
use strict;
use Carp qw/croak/;
use vars qw/$VERSION/;
$VERSION = '0.9901';

#--------------------------------------------------------------------------#
# Class data
#--------------------------------------------------------------------------#

my @data = (0);

#--------------------------------------------------------------------------#
# new()
#--------------------------------------------------------------------------#

sub new {
    my ($class, @data) = @_;
    my $self = bless ([], ref ($class) || $class);
    $self->srand(@data);
    return $self;
}

#--------------------------------------------------------------------------#
# srand()
#--------------------------------------------------------------------------#

sub srand { ## no critic
    if (ref ($_[0]) eq __PACKAGE__) {
        my $self = shift;
        @$self = $self->_test_srand(@_);
        return;
    } else {
        @data = Test::MockRandom->_test_srand(@_);
        return;
    }
}

sub _test_srand {
    my ($self, @data) = @_;
    my $error = "Seeds for " . __PACKAGE__ . 
                " must be between 0 (inclusive) and 1 (exclusive)";
    croak $error if grep { $_ < 0 or $_ >= 1 } @data;    
    return @data ? @data : ( 0 );
}

#--------------------------------------------------------------------------#
# rand()
#--------------------------------------------------------------------------#

sub rand(;$) { ## no critic
    my ($mult,$val);
    if (ref ($_[0]) eq __PACKAGE__) { # we're a MockRandom object
        $mult = $_[1];
        $val = shift @{$_[0]} || 0;
    } else {
        # we might be called as a method of some other class
        # so we need to ignore that and get the right multiplier
        $mult = $_[ ref($_[0]) ? 1 : 0];
        $val =  shift @data || 0;
    }
    # default to 1 for undef, 0, or strings that aren't numbers
    eval { local $^W = 0; my $bogus = 1/$mult };
    $mult = 1 if $@;    
    return $val * $mult;
}

#--------------------------------------------------------------------------#
# oneish()
#--------------------------------------------------------------------------#

sub oneish {
    return (2**32-1)/(2**32);	
}

#--------------------------------------------------------------------------#
# import()
#--------------------------------------------------------------------------#

sub import {
    my ($class, @import_list) = @_;
    my $caller = caller(0);
    
    # Nothing exported by default or if empty string requested
    return unless @import_list;
    return if ( @import_list == 1 && $import_list[0] eq '' );

    for my $tgt ( @import_list ) {
        # custom handling if it's a hashref
        if ( ref($tgt) eq "HASH" ) {
            for my $sym ( keys %$tgt ) {
                croak "Unrecognized symbol '$sym'" 
                    unless grep { $sym eq $_ } qw (rand srand oneish);
                my @custom = ref($tgt->{$sym}) eq 'ARRAY' ? 
                @{$tgt->{$sym}} : $tgt->{$sym};
                _custom_export( $sym, $_ ) for ( @custom );
            }
        }
        # otherwise, export rand to target and srand/oneish to caller
        else {
            my $pkg = ($tgt =~ /^__PACKAGE__$/) ? $caller : $tgt; # DWIM
            _export_symbol("rand",$pkg);
            _export_symbol($_,$caller) for qw( srand oneish );
        }
    }
    return;
}

#--------------------------------------------------------------------------#
# export_oneish_to()
#--------------------------------------------------------------------------#

sub export_oneish_to {
    my ($class, @args) = @_;
    _export_fcn_to($class, "oneish", @args);
    return;
}

#--------------------------------------------------------------------------#
# export_rand_to()
#--------------------------------------------------------------------------#

sub export_rand_to {
    my ($class, @args) = @_;
    _export_fcn_to($class, "rand", @args);
    return;
}

#--------------------------------------------------------------------------#
# export_srand_to()
#--------------------------------------------------------------------------#

sub export_srand_to {
    my ($class, @args) = @_;
    _export_fcn_to($class, "srand", @args);
    return;
}

#--------------------------------------------------------------------------#
# _custom_export
#--------------------------------------------------------------------------#

sub _custom_export {
    my ($sym,$custom) = @_;
    if ( ref($custom) eq 'HASH' ) {
        _export_symbol( $sym, %$custom ); # flatten { pkg => 'alias' }
    }
    else {
        _export_symbol( $sym, $custom );
    }
    return;
}

#--------------------------------------------------------------------------#
# _export_fcn_to
#--------------------------------------------------------------------------#

sub _export_fcn_to {
    my ($self, $fcn, $pkg, $alias) = @_;
    croak "Must call to export_${fcn}_to() as a class method"
        unless ( $self eq __PACKAGE__ );
    croak("export_${fcn}_to() requires a package name") unless $pkg;
    _export_symbol($fcn,$pkg,$alias);
    return;
}

#--------------------------------------------------------------------------#
# _export_symbol()
#--------------------------------------------------------------------------#

sub _export_symbol {
    my ($sym,$pkg,$alias) = @_;
    $alias ||= $sym;
    {
        no strict 'refs'; ## no critic
        local $^W = 0; # no redefine warnings
        *{"${pkg}::${alias}"} = \&{"Test::MockRandom::${sym}"};
    }
    return;
}

1; #this line is important and will help the module return a true value
__END__

=begin wikidoc

= NAME

Test::MockRandom -  Replaces random number generation with non-random number
generation

= VERSION

This documentation describes version %%VERSION%%.

= SYNOPSIS

  # intercept rand in another package
  use Test::MockRandom 'Some::Other::Package';
  use Some::Other::Package; # exports sub foo { return rand }
  srand(0.13);
  foo(); # returns 0.13
  
  # using a seed list and "oneish"
  srand(0.23, 0.34, oneish() );
  foo(); # returns 0.23
  foo(); # returns 0.34
  foo(); # returns a number just barely less than one
  foo(); # returns 0, as the seed array is empty
  
  # object-oriented, for use in the current package
  use Test::MockRandom ();
  my $nrng = Test::MockRandom->new(0.42, 0.23);
  $nrng->rand(); # returns 0.42
  
= DESCRIPTION

This perhaps ridiculous-seeming module was created to test routines that
manipulate random numbers by providing a known output from {rand}.  Given a
list of seeds with {srand}, it will return each in turn.  After seeded random
numbers are exhausted, it will always return 0.  Seed numbers must be of a form
that meets the expected output from {rand} as called with no arguments -- i.e.
they must be between 0 (inclusive) and 1 (exclusive).  In order to facilitate
generating and testing a nearly-one number, this module exports the function
{oneish}, which returns a number just fractionally less than one.  

Depending on how this module is called with {use}, it will export {rand} to a
specified package (e.g. a class being tested) effectively overriding and
intercepting calls in that package to the built-in {rand}.  It can also
override {rand} in the current package or even globally.  In all
of these cases, it also exports {srand} and {oneish} to the current package
in order to control the output of {rand}.  See [/USAGE] for details.

Alternatively, this module can be used to generate objects, with each object
maintaining its own distinct seed array.

= USAGE

By default, Test::MockRandom does not export any functions.  This still allows
object-oriented use by calling {Test::MockRandom->new(@seeds)}.  In order
for Test::MockRandom to be more useful, arguments must be provided during the
call to {use}.

== use Test::MockRandom 'Target::Package'

The simplest way to intercept {rand} in another package is to provide the
name(s) of the package(s) for interception as arguments in the {use}
statement.  This will export {rand} to the listed packages and will export
{srand} and {oneish} to the current package to control the behavior of
{rand}.  You *must* {use} Test::MockRandom before you {use} the target
package.  This is a typical case for testing a module that uses random numbers:

 use Test::More 'no_plan';
 use Test::MockRandom 'Some::Package';
 BEGIN { use_ok( Some::Package ) }
 
 # assume sub foo { return rand } was imported from Some::Package
 
 srand(0.5)
 is( foo(), 0.5, "is foo() 0.5?") # test gives "ok"

If multiple package names are specified, {rand} will be exported to all
of them.

If you wish to export {rand} to the current package, simply provide
{__PACKAGE__} as the parameter for {use}, or {main} if importing
to a script without a specified package.  This can be part of a
list provided to {use}.  All of the following idioms work:

 use Test::MockRandom qw( main Some::Package ); # Assumes a script
 use Test::MockRandom __PACKAGE__, 'Some::Package';

 # The following doesn't interpolate __PACKAGE__ as above, but 
 # Test::MockRandom will still DWIM and handle it correctly

 use Test::MockRandom qw( __PACKAGE__ Some::Package );

== use Test::MockRandom \%customized

As an alternative to a package name as an argument to {use},
Test::MockRandom will also accept a hash reference with a custom
set of instructions for how to export functions:

 use Test::MockRandom {
    rand   => [ Some::Package, {Another::Package => 'random'} ],
    srand  => { Another::Package => 'seed' }, 
    oneish => __PACKAGE__
 };

The keys of the hash may be any of {rand}, {srand}, and {oneish}.  The
values of the hash give instructions for where to export the symbol
corresponding to the key.  These are interpreted as follows, depending on their
type:

* String: a package to which Test::MockRandom will export the symbol
* Hash Reference: the key is the package to which Test::MockRandom will export
the symbol and the value is the name under which it will be exported
* Array Reference: a list of strings or hash references which will be handled
as above

== Test::MockRandom->export_rand_to()

In order to intercept the built-in {rand} in another package, 
Test::MockRandom must export its own {rand} function to the 
target package *before* the target package is compiled, thus overriding
calls to the built-in.  The simple approach (described above) of providing the
target package name in the {use Test::MockRandom} statement accomplishes this
because {use} is equivalent to a {require} and {import} within a {BEGIN}
block.  To explicitly intercept {rand} in another package, you can also call
{export_rand_to}, but it must be enclosed in a {BEGIN} block of its own.  The
explicit form also support function aliasing just as with the custom approach
with {use}, described above:

 use Test::MockRandom;
 BEGIN {Test::MockRandom->export_rand_to('AnotherPackage'=>'random')}
 use AnotherPackage;
 
This {BEGIN} block must not include a {use} statement for the package to be
intercepted, or perl will compile the package to be intercepted before the
{export_rand_to} function has a chance to execute and intercept calls to 
the built-in {rand}.  This is very important in testing.  The {export_rand_to}
call must be in a separate {BEGIN} block from a {use} or {use_ok} test,
which should be enclosed in a {BEGIN} block of its own: 
 
 use Test::More tests => 1;
 use Test::MockRandom;
 BEGIN { Test::MockRandom->export_rand_to( 'AnotherPackage' ); }
 BEGIN { use_ok( 'AnotherPackage' ); }

Given these cautions, it's probably best to use either the simple or custom
approach with {use}, which does the right thing in most circumstances.  Should
additional explicit customization be necessary, Test::MockRandom also provides
{export_srand_to} and {export_oneish_to}.

== Overriding {rand} globally: use Test::MockRandom 'CORE::GLOBAL'

This is just like intercepting {rand} in a package, except that you
do it globally by overriding the built-in function in {CORE::GLOBAL}. 

 use Test::MockRandom 'CORE::GLOBAL';
 
 # or

 BEGIN { Test::MockRandom->export_rand_to('CORE::GLOBAL') }

You can always access the real, built-in {rand} by calling it explicitly as
{CORE::rand}.

== Intercepting {rand} in a package that also contains a {rand} function

This is tricky as the order in which the symbol table is manipulated will lead
to very different results.  This can be done safely (maybe) if the module uses
the same rand syntax/prototype as the system call but offers them up as method
calls which resolve at run-time instead of compile time.  In this case, you
will need to do an explicit intercept (as above) but do it *after* importing
the package.  I.e.:

 use Test::MockRandom 'SomeRandPackage';
 use SomeRandPackage;
 BEGIN { Test::MockRandom->export_rand_to('SomeRandPackage');

The first line is necessary to get {srand} and {oneish} exported to
the current package.  The second line will define a {sub rand} in 
{SomeRandPackage}, overriding the results of the first line.  The third
line then re-overrides the {rand}.  You may see warnings about {rand} 
being redefined.

Depending on how your {rand} is written and used, there is a good likelihood
that this isn't going to do what you're expecting, no matter what.  If your
package that defines {rand} relies internally upon the system
{CORE::GLOBAL::rand} function, then you may be best off overriding that
instead.

= FUNCTIONS

== {new}

 $obj = new( LIST OF SEEDS );

Returns a new Test::MockRandom object with the specified list of seeds.

== {srand}

 srand( LIST OF SEEDS );
 $obj->srand( LIST OF SEEDS);

If called as a bare function call or package method, sets the seed list
for bare/package calls to {rand}.  If called as an object method,
sets the seed list for that object only.

== {rand}

 $rv = rand();
 $rv = $obj->rand();
 $rv = rand(3);

If called as a bare or package function, returns the next value from the
package seed list.  If called as an object method, returns the next value from
the object seed list. 

If {rand} is called with a numeric argument, it follows the same behavior as
the built-in function -- it multiplies the argument with the next value from
the seed array (resulting in a random fractional value between 0 and the
argument, just like the built-in).  If the argument is 0, undef, or
non-numeric, it is treated as if the argument is 1.

Using this with an argument in testing may be complicated, as limits in
floating point precision mean that direct numeric comparisons are not reliable.
E.g.

 srand(1/3);
 rand(3);       # does this return 1.0 or .999999999 etc.

== {oneish}

 srand( oneish() );
 if ( rand() == oneish() ) { print "It's almost one." };

A utility function to return a nearly-one value.  Equal to ( 2^32 - 1 ) / 2^32.
Useful in {srand} and test functions.

== {export_rand_to}

 Test::MockRandom->export_rand_to( 'Some::Class' );
 Test::MockRandom->export_rand_to( 'Some::Class' => 'random' );

This function exports {rand} into the specified package namespace.  It must be
called as a class function.  If a second argument is provided, it is taken as
the symbol name used in the other package as the alias to {rand}:
 
 use Test::MockRandom;
 BEGIN { Test::MockRandom->export_rand_to( 'Some::Class' => 'random' ); }
 use Some::Class;
 srand (0.5);
 print Some::Class::random(); # prints 0.5

It can also be used to explicitly intercept {rand} after Test::MockRandom has
been loaded.  The effect of this function is highly dependent on when it is
called in the compile cycle and should usually called from within a BEGIN
block.  See [/USAGE] for details.

Most users will not need this function.

== {export_srand_to}

 Test::MockRandom->export_srand_to( 'Some::Class' );
 Test::MockRandom->export_srand_to( 'Some::Class' => 'seed' );

This function exports {srand} into the specified package namespace.  It must be 
called as a class function.  If a second argument is provided, it is taken as
the symbol name to use in the other package as the alias for {srand}.
This function may be useful if another package wraps {srand}:
 
 # In Some/Class.pm
 package Some::Class;
 sub seed { srand(shift) }
 sub foo  { rand }

 # In a script
 use Test::MockRandom 'Some::Class';
 BEGIN { Test::MockRandom->export_srand_to( 'Some::Class' ); }
 use Some::Class;
 seed(0.5);
 print foo();   # prints "0.5"

The effect of this function is highly dependent on when it is called in the
compile cycle and should usually be called from within a BEGIN block.  See
[/USAGE] for details.

Most users will not need this function.  

== {export_oneish_to}

 Test::MockRandom->export_oneish_to( 'Some::Class' );
 Test::MockRandom->export_oneish_to( 'Some::Class' => 'nearly_one' );

This function exports {oneish} into the specified package namespace.  It must
be called as a class function.  If a second argument is provided, it is taken
as the symbol name to use in the other package as the alias for {oneish}.  
Since {oneish} is usually only used in a test script, this function is likely
only necessary to alias {oneish} to some other name in the current package:

 use Test::MockRandom 'Some::Class';
 BEGIN { Test::MockRandom->export_oneish_to( __PACKAGE__, "one" ); }
 use Some::Class;
 seed( one() );
 print foo();   # prints a value very close to one

The effect of this function is highly dependent on when it is called in the
compile cycle and should usually be called from within a BEGIN block.  See
[/USAGE] for details.

Most users will not need this function.  

= BUGS

Please report any bugs or feature requests using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
[http://rt.cpan.org/Dist/Display.html?Queue=Test::MockRandom]

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

= SEE ALSO

* Test::MockObject
* Test::MockModule

= AUTHOR

David A. Golden (DAGOLDEN)

= COPYRIGHT AND LICENSE

Copyright (c) 2004-2007 by David A. Golden

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 
[http://www.apache.org/licenses/LICENSE-2.0]

Files produced as output though the use of this software, shall not be
considered Derivative Works, but shall be considered the original work of the
Licensor.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=end wikidoc

=cut

