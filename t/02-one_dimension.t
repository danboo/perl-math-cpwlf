use warnings;
use strict;

use Test::More 'no_plan';

use Carp;

$SIG{__WARN__} = \&Carp::confess;

use Math::CPWLF;

my $f = Math::CPWLF->new; 

$f->knot( 0 => 1 );

is( $f->(0),  1, 'add one knot' );
is( $f->(-1), 1, '. . . left-wise OOB' );
is( $f->(2),  1, '. . . right-wise OOB' );

$f->knot( 2 => 5 );

is( $f->(2),   5, 'add a second knot' );
is( $f->(0), 1, '. . . direct hit' );
is( $f->(-1),  1, '. . . left-wise OOB' );
is( $f->(3),   5, '. . . right-wise OOB' );
is( $f->(1),   3, '. . . interpolate' );

$f->knot( 2 => 7 );

is( $f->(2),   7, 'replace second knot' );
is( $f->(0),   1, '. . . direct hit' );
is( $f->(-1),  1, '. . . left-wise OOB' );
is( $f->(3),   7, '. . . right-wise OOB' );
is( $f->(1),   4, '. . . interpolate' );

$f->knot( 102 => 207 );

is( $f->(102), 207, 'add third knot' );
is( $f->(0),   1, '. . . direct hit - 0' );
is( $f->(2),   7, '. . . direct hit - 2' );
is( $f->(-1),  1, '. . . left-wise OOB' );
is( $f->(503), 207, '. . . right-wise OOB' );
is( $f->(50),  103, '. . . interpolate' );

## verify that user input is normalized via numification

is( $f->("02"),   7, 'normalize lookup x' );

$f->("02" => 7);

is( $f->(2),      7, 'normalize knot() x' );
