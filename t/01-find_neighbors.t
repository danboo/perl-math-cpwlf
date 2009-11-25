use warnings;
use strict;

use Test::More 'no_plan';

use Math::CPWLF;

my @tests =
   (

   [ 'none',                      [ undef, undef, {} ],           [ ],     1,   undef, undef ],

   [ 'one - direct',              [ 0, 0, {} ],                   [ 1 ],   1,   undef, undef ],

   [ 'two - left direct',         [ 0, 0, {} ],                   [ 1,2 ], 1,   undef, undef ],
   [ 'two - right direct',        [ 1, 1, {} ],                   [ 1,2 ], 2,   undef, undef ],
   [ 'two - between',             [ 0, 1, {} ],                   [ 1,2 ], 1.5, undef, undef ],

   [ 'three - left direct',         [ 0, 0, {} ],                 [ 1,2,3 ], 1,   undef, undef ],
   [ 'three - middle direct',       [ 1, 1, {} ],                 [ 1,2,3 ], 2,   undef, undef ],
   [ 'three - right direct',        [ 2, 2, {} ],                 [ 1,2,3 ], 3,   undef, undef ],
   [ 'three - between bottom',      [ 0, 1, {} ],                 [ 1,2,3 ], 1.5, undef, undef ],
   [ 'three - between top',         [ 1, 2, {} ],                 [ 1,2,3 ], 2.5, undef, undef ],

   );
   
for my $t ( @tests )
   {
   
   my $name = shift @{ $t };
   my $exp  = shift @{ $t };
   
   my @got = Math::CPWLF::_find_neighbors( @{ $t } );
   
   is_deeply( \@got, $exp, $name );
   
   }