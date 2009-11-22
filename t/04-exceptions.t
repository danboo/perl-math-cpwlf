use warnings;
use strict;

use Test::More 'no_plan';

use Carp;

$SIG{__WARN__} = \&Carp::confess;

use Math::CPWLF;

{
my $f = Math::CPWLF->new;
my $y = eval { $f->(1) };
like( $@, qr/Error: cannot interpolate with no knots/, 'no knots' );
}

