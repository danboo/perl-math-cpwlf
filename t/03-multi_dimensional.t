use warnings;
use strict;

use Test::More 'no_plan';

use Math::CPWLF;

my $fy0 = Math::CPWLF->new;

$fy0->knot( 10, 30 );
$fy0->knot( 20, 50 );

my $fy2 = Math::CPWLF->new;

$fy2->knot( 10, 30 );
$fy2->knot( 20, 60 );

my $fx = Math::CPWLF->new; 

$fx->knot( 0 => $fy0 );
$fx->knot( 2 => $fy2 );

is( $fx->(0)(10), 30,   'hit, hit' );
is( $fx->(0)(15), 40,   'hit, interpolate' );
is( $fx->(1)(20), 55,   'interpolate, hit' );
is( $fx->(1)(15), 42.5, 'interpolate, interpolate' );

