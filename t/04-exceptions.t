use warnings;
use strict;

use Test::More 'no_plan';

use Carp;

$SIG{__WARN__} = \&Carp::confess;

use Math::CPWLF;

{

my $f = Math::CPWLF->new;

eval { $f->(1) };
like( $@, qr/\QError: cannot interpolate with no knots/, 'no knots' );

}

{

my $f = Math::CPWLF->new;

$f->knot( 1, 1 );
eval { $f->(2) };
like( $@, qr/\QError: given X (2) was out of bounds of function min or max/, '2 oob default' );

$f->knot( 2, 2 );
eval { $f->(3) };
like( $@, qr/\QError: given X (3) was out of bounds of function min or max/, '3 oob default' );

eval { $f->(0) };
like( $@, qr/\QError: given X (0) was out of bounds of function min or max/, '0 oob default' );

}

{

my $f = Math::CPWLF->new( oob => 'level' );

$f->knot( 1, 1 );
my $y = $f->(2);
is($y, 1, '2 oob level' );

$f->knot( 2, 2 );
$y = $f->(3);
is($y, 2, '3 oob level' );

$y = $f->(0);
is($y, 1, '0 oob level' );

}
