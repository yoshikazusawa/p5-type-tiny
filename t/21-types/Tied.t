=pod

=encoding utf-8

=head1 PURPOSE

Basic tests for B<Tied> from L<Types::Standard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019-2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::TypeTiny;
use Types::Standard qw( Tied );

isa_ok(Tied, 'Type::Tiny', 'Tied');
is(Tied->name, 'Tied', 'Tied has correct name');
is(Tied->display_name, 'Tied', 'Tied has correct display_name');
is(Tied->library, 'Types::Standard', 'Tied knows it is in the Types::Standard library');
ok(Types::Standard->has_type('Tied'), 'Types::Standard knows it has type Tied');
ok(!Tied->deprecated, 'Tied is not deprecated');
ok(!Tied->is_anon, 'Tied is not anonymous');
ok(Tied->can_be_inlined, 'Tied can be inlined');
is(exception { Tied->inline_check(q/$xyz/) }, undef, "Inlining Tied doesn't throw an exception");
ok(!Tied->has_coercion, "Tied doesn't have a coercion");
ok(Tied->is_parameterizable, "Tied is parameterizable");

#
# The @tests array is a list of triples:
#
# 1. Expected result - pass, fail, or xxxx (undefined).
# 2. A description of the value being tested.
# 3. The value being tested.
#

my @tests = (
	fail => 'undef'                    => undef,
	fail => 'false'                    => !!0,
	fail => 'true'                     => !!1,
	fail => 'zero'                     =>  0,
	fail => 'one'                      =>  1,
	fail => 'negative one'             => -1,
	fail => 'non integer'              =>  3.1416,
	fail => 'empty string'             => '',
	fail => 'whitespace'               => ' ',
	fail => 'line break'               => "\n",
	fail => 'random string'            => 'abc123',
	fail => 'loaded package name'      => 'Type::Tiny',
	fail => 'unloaded package name'    => 'This::Has::Probably::Not::Been::Loaded',
	fail => 'a reference to undef'     => do { my $x = undef; \$x },
	fail => 'a reference to false'     => do { my $x = !!0; \$x },
	fail => 'a reference to true'      => do { my $x = !!1; \$x },
	fail => 'a reference to zero'      => do { my $x = 0; \$x },
	fail => 'a reference to one'       => do { my $x = 1; \$x },
	fail => 'a reference to empty string' => do { my $x = ''; \$x },
	fail => 'a reference to random string' => do { my $x = 'abc123'; \$x },
	fail => 'blessed scalarref'        => bless(do { my $x = undef; \$x }, 'SomePkg'),
	fail => 'empty arrayref'           => [],
	fail => 'arrayref with one zero'   => [0],
	fail => 'arrayref of integers'     => [1..10],
	fail => 'arrayref of numbers'      => [1..10, 3.1416],
	fail => 'blessed arrayref'         => bless([], 'SomePkg'),
	fail => 'empty hashref'            => {},
	fail => 'hashref'                  => { foo => 1 },
	fail => 'blessed hashref'          => bless({}, 'SomePkg'),
	fail => 'coderef'                  => sub { 1 },
	fail => 'blessed coderef'          => bless(sub { 1 }, 'SomePkg'),
	fail => 'glob'                     => do { no warnings 'once'; *SOMETHING },
	fail => 'globref'                  => do { no warnings 'once'; my $x = *SOMETHING; \$x },
	fail => 'blessed globref'          => bless(do { no warnings 'once'; my $x = *SOMETHING; \$x }, 'SomePkg'),
	fail => 'regexp'                   => qr/./,
	fail => 'blessed regexp'           => bless(qr/./, 'SomePkg'),
	fail => 'filehandle'               => do { open my $x, '<', $0 or die; $x },
	fail => 'filehandle object'        => do { require IO::File; 'IO::File'->new($0, 'r') },
	fail => 'ref to scalarref'         => do { my $x = undef; my $y = \$x; \$y },
	fail => 'ref to arrayref'          => do { my $x = []; \$x },
	fail => 'ref to hashref'           => do { my $x = {}; \$x },
	fail => 'ref to coderef'           => do { my $x = sub { 1 }; \$x },
	fail => 'ref to blessed hashref'   => do { my $x = bless({}, 'SomePkg'); \$x },
	fail => 'object stringifying to ""' => do { package Local::OL::StringEmpty; use overload q[""] => sub { "" }; bless [] },
	fail => 'object stringifying to "1"' => do { package Local::OL::StringOne; use overload q[""] => sub { "1" }; bless [] },
	fail => 'object numifying to 0'    => do { package Local::OL::NumZero; use overload q[0+] => sub { 0 }; bless [] },
	fail => 'object numifying to 1'    => do { package Local::OL::NumOne; use overload q[0+] => sub { 1 }; bless [] },
	fail => 'object overloading arrayref' => do { package Local::OL::Array; use overload q[@{}] => sub { $_[0]{array} }; bless {array=>[]} },
	fail => 'object overloading hashref' => do { package Local::OL::Hash; use overload q[%{}] => sub { $_[0][0] }; bless [{}] },
	fail => 'object overloading coderef' => do { package Local::OL::Code; use overload q[&{}] => sub { $_[0][0] }; bless [sub { 1 }] },
#TESTS
);

while (@tests) {
	my ($expect, $label, $value) = splice(@tests, 0 , 3);
	if ($expect eq 'xxxx') {
		note("UNDEFINED OUTCOME: $label");
	}
	elsif ($expect eq 'pass') {
		should_pass($value, Tied, ucfirst("$label should pass Tied"));
	}
	elsif ($expect eq 'fail') {
		should_fail($value, Tied, ucfirst("$label should fail Tied"));
	}
	else {
		fail("expected '$expect'?!");
	}
}

#
# Test with tied scalar
#

require Tie::Scalar;
tie my $var, 'Tie::StdScalar';

should_pass( \$var, Tied );
should_pass( \$var, Tied['Tie::StdScalar'] );
should_pass( \$var, Tied['Tie::Scalar'] );
should_fail( \$var, Tied['IO::File'] );    # Tie::StdScalar inherits

#
# Blessed scalarrefs can still be tied
#

bless(\$var, 'Bleh');
should_pass( \$var, Tied['Tie::Scalar'] );
should_fail( \$var, Tied['Bleh'] );

#
# Tied is for blessed references only!
# Couldn't reliably test non-reference even if we wanted to.
#

ok(tied($var), '$var is tied');
should_fail( $var, Tied );

#
# Test with tied array
#

require Tie::Array;
tie my @arr, 'Tie::StdArray';
should_pass( \@arr, Tied );
should_pass( \@arr, Tied['Tie::StdArray'] );
should_pass( \@arr, Tied['Tie::Array'] );
should_fail( \@arr, Tied['IO::File'] );    # Tie::StdArray inherits

#
# Blessed arrayrefs can still be tied
#

bless(\@arr, 'Bleh');
should_pass( \@arr, Tied['Tie::Array'] );
should_fail( \@arr, Tied['Bleh'] );

#
# Test with tied hash
#

require Tie::Hash;
@Tie::StdHash::ISA = qw(Tie::Hash);
tie my %h, 'Tie::StdHash';
should_pass( \%h, Tied );
should_pass( \%h, Tied['Tie::StdHash'] );
should_pass( \%h, Tied['Tie::Hash'] );
should_fail( \%h, Tied['IO::File'] );    # Tie::StdHash inherits

#
# Blessed hashrefs can still be tied
#

bless(\%h, 'Bleh');
should_pass( \%h, Tied['Tie::Hash'] );
should_fail( \%h, Tied['Bleh'] );

done_testing;

