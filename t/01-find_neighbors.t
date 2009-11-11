use warnings;
use strict;

use Test::More 'no_plan';

use Math::CPWLF;

my @tests =
   (

   [ 'none',                      [ undef, undef ], [ ],     1,   undef, undef ],

   [ 'one - direct',              [ 1, 1 ],         [ 1 ],   1,   undef, undef ],
   [ 'one - left out of bounds',  [ 1, 1 ],         [ 1 ],   0,   undef, undef ],
   [ 'one - right out of bounds', [ 1, 1 ],         [ 1 ],   2,   undef, undef ],

   [ 'two - left direct',         [ 1, 1 ],         [ 1,2 ], 1,   undef, undef ],
   [ 'two - right direct',        [ 2, 2 ],         [ 1,2 ], 2,   undef, undef ],
   [ 'two - left out of bounds',  [ 1, 1 ],         [ 1,2 ], 0,   undef, undef ],
   [ 'two - right out of bounds', [ 2, 2 ],         [ 1,2 ], 3,   undef, undef ],
   [ 'two - between',             [ 1, 2 ],         [ 1,2 ], 1.5, undef, undef ],

   [ 'three - left direct',         [ 1, 1 ],         [ 1,2,3 ], 1,   undef, undef ],
   [ 'three - middle direct',       [ 2, 2 ],         [ 1,2,3 ], 2,   undef, undef ],
   [ 'three - right direct',        [ 3, 3 ],         [ 1,2,3 ], 3,   undef, undef ],
   [ 'three - left out of bounds',  [ 1, 1 ],         [ 1,2,3 ], 0,   undef, undef ],
   [ 'three - right out of bounds', [ 3, 3 ],         [ 1,2,3 ], 4,   undef, undef ],
   [ 'three - between bottom',      [ 1, 2 ],         [ 1,2,3 ], 1.5, undef, undef ],
   [ 'three - between top',         [ 2, 3 ],         [ 1,2,3 ], 2.5, undef, undef ],

   );
   
for my $t ( @tests )
   {
   
   my $name = shift @{ $t };
   my $exp  = shift @{ $t };
   
   my @got = Math::CPWLF::_find_neighbors( @{ $t } );
   
   is_deeply( \@got, $exp, $name );
   
   }