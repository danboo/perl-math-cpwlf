use warnings;
use strict;

use Test::More 'no_plan';

use Carp;

$SIG{__WARN__} = \&Carp::confess;

use Math::CPWLF;

my $fy0 = Math::CPWLF->new;

$fy0->knot( 10, 30 );
$fy0->knot( 20, 50 );

my $fy2 = Math::CPWLF->new;

$fy2->knot( 10, 30 );
$fy2->knot( 20, 70 );

my $fx = Math::CPWLF->new; 

$fx->knot( 0 => $fy0 );
$fx->knot( 2 => $fy2 );
$fx->knot( 4 => 100 );

is( $fx->(0)(10), 30, 'hit, hit' );
is( $fx->(0)(15), 40, 'hit, interpolate' );
is( $fx->(1)(20), 60, 'interpolate, hit' );
is( $fx->(1)(15), 45, 'interpolate, interpolate' );
is( $fx->(3)(15), 75, 'interpolate, interpolate - 1.5 dimensions' );

my $f = Math::CPWLF->new;
for my $a ( 1 .. 5 )
   {
   my $fa = Math::CPWLF->new;
   $f->knot( $a, $fa );
   for my $b ( 1 .. 5 )
      {
      my $fb = Math::CPWLF->new;
      $fa->knot( $b, $fb );
      for my $c ( 1 .. 5 )
         {
         my $fc = Math::CPWLF->new;
         $fb->knot( $c, $fc );
         for my $d ( 1 .. 5 )
            {
            $fc->knot( $d, $d * 2 );
            }
         }
      }
   }


my $f_multi_knot = Math::CPWLF->new;
for my $a ( 1 .. 5 )
   {
   for my $b ( 1 .. 5 )
      {
      for my $c ( 1 .. 5 )
         {
         for my $d ( 1 .. 5 )
            {
            $f_multi_knot->knot( $a, $b, $c, $d => $d * 2 );
            }
         }
      }
   }
   
for my $pair ( [ $f, 'manual'], [ $f_multi_knot, 'multi' ] )
   {
   my ( $func, $name ) = @{ $pair };
   is( ref $func->(1),          'CODE', $name . ': dimension 2 is CODE' );
   is( ref $func->(1)(1),       'CODE', $name . ': dimension 3 is CODE' );
   is( ref $func->(1)(1)(1),    'CODE', $name . ': dimension 4 is CODE' );
   is( ref $func->(1)(1)(1)(1),    '',  $name . ': dimension 5 is a value' );
   is( $func->(1)(1)(1)(1),         2,  $name . ': all hits' );
   is( $func->(1.5)(1.5)(1.5)(1.5), 3,  $name . ': all interps' );
   is( $func->(1.5)(2.5)(3.5)(4.5), 9,  $name . ': increasing interps' );
   }


