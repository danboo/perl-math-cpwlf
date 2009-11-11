use warnings;
use strict;

use Test::More 'no_plan';

use Math::CPWLF;

my $f = Math::CPWLF->new;

$f->knot( 0 => 1 );

is( $f->(0), 1, 'f(0)' );