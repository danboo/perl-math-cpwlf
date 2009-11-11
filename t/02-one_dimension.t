use warnings;
use strict;

use Test::More 'no_plan';

use Math::CPWLF;

my $f = Math::CPWLF->new; 

is( $f->(0), undef, 'no knots' );

$f->knot( 0 => 1 );

is( $f->(0),  1, 'one - direct hit' );
is( $f->(-1), 1, 'one - left-wise OOB' );
is( $f->(2),  1, 'one - right-wise OOB' );

$f->knot( 2 => 5 );

is( $f->(0),   1, 'two - direct hit' );
is( $f->(-1),  1, 'two - left-wise OOB' );
is( $f->(3),   5, 'two - right-wise OOB' );
is( $f->(1),   3, 'two - interpolate' );
