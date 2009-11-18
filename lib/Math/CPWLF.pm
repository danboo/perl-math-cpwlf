package Math::CPWLF;

use warnings;
use strict;

=head1 NAME

Math::CPWLF - Multidimensional interpolation using continuous piece-wise linear
              functions

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Math::CPWLF;

    my $foo = Math::CPWLF->new();
    ...

=head1 EXPORT

None

=head1 FUNCTIONS

=head2 new

=cut

use overload
   '&{}'    => sub { my $self = $_[0]; return _interp_closure( [ [ $self ] ] ) },
   fallback => 1;

sub new
  {
  my $self  = bless {}, shift();
  return $self;
  }
  
=head2 knot

=cut

sub knot
  {
  my ($self, $key, $val) = @_;
  $self->{'_data'}{$key} = $val;
  delete $self->{'_keys'};
  return $self;
  }
  
sub _interp_closure
   {
   my ( $stack ) = @_;
   
   my $interp = sub
      {
      my ($x_given) = @_;
      
      ## for each closured cpwlf
      ##   get the two neighbor x,y pairs
      ## if any y is a cpwlf
      ##   return a new closure around all x,y pairs unshifted onto a dimension-based cpwlf stack
      ## else work back through the stacks of x,y pairs and keys
      ##
      ## { 
      ##   neighbor_dn => [x,y],
      ##   neighbor_up => [x,y],
      ##   key         => $key,
      ## }
      ## if y is a cpwlf
      ##    - 
          
      
      my @results;
      my $make_closure;
      
      for my $value ( @{ $stack->[-1] } )
         {
            
         if ( ref $value eq 'HASH' )
            {
               
            if ( ref $value->{y_dn} )
               {
               my ($x_dn, $x_up, $y_dn, $y_up) = $value->{y_dn}->_neighbors($x_given);
               
               if ( ref $y_dn || ref $y_up )
                  {
                  $make_closure = 1;
                  }

               push @results,
                  {
                  x_given => $x_given,
                  x_dn    => $x_dn,
                  y_dn    => $y_dn,
                  x_up    => $x_up,
                  y_up    => $y_up,
                  into    => [ $value, 'y_dn' ],
                  };
               }

            if ( ref $value->{y_up} )
               {
               my ($x_dn, $x_up, $y_dn, $y_up) = $value->{y_up}->_neighbors($x_given);
               
               if ( ref $y_dn || ref $y_up )
                  {
                  $make_closure = 1;
                  }

               push @results,
                  {
                  x_given => $x_given,
                  x_dn    => $x_dn,
                  y_dn    => $y_dn,
                  x_up    => $x_up,
                  y_up    => $y_up,
                  into    => [ $value, 'y_up' ],
                  };
               }

            }
         else
            {

            my ($x_dn, $x_up, $y_dn, $y_up) = $value->_neighbors($x_given);
            
            push @results,
               {
               x_given => $x_given,
               x_dn    => $x_dn,
               y_dn    => $y_dn,
               x_up    => $x_up,
               y_up    => $y_up,
               };

            if ( ref $y_dn || ref $y_up )
               {
               $make_closure = 1;
               }

            }

         }
         
      push @{ $stack }, \@results;
      
      if ( $make_closure )
         {
         
         return _interp_closure( $stack );
         
         }
      else
         {
            
         ## unwind stacks and solve from the leaves to the trunk
         
      use Data::Dumper;
      print Dumper $stack;
         
         }
         
      };

   return $interp;   
   }

sub _neighbors
   {
   my ($self, $key) = @_;
  
   if ( ! exists $self->{'_keys'} )
      {
      $self->_order_keys;
      }
     
   if ( ! @{ $self->{'_keys'} } )
      {
      return;
      }
     
   my ( $x_dn_i, $x_up_i ) = _find_neighbors( $self->{'_keys'}, $key );
 
   my $x_dn = $self->{'_keys'}[ $x_dn_i ];
   my $x_up = $self->{'_keys'}[ $x_up_i ];

   my $y_dn = $self->{'_data'}{$x_dn};
   my $y_up = $self->{'_data'}{$x_up};

   return $x_dn, $x_up, $y_dn, $y_up;
   }


sub _value
  {
  my ($self, $key) = @_;
  
  if ( ! exists $self->{'_keys'} )
     {
     $self->_order_keys;
     }
     
  if ( ! @{ $self->{'_keys'} } )
     {
     return;
     }
     
  my ( $x_dn_i, $x_up_i ) = _find_neighbors( $self->{'_keys'}, $key );
  
  my $x_dn = $self->{'_keys'}[ $x_dn_i ];
  my $x_up = $self->{'_keys'}[ $x_up_i ];

  my $lower = $self->{'_data'}{$x_dn};
  my $upper = $self->{'_data'}{$x_up};

  my $interp = _generate_interp_closure( $lower, $upper, $key, $x_dn, $x_up );
        
  my $recurse = ref $lower || ref $upper;

  return $recurse
       ? $interp
       : $interp->($key);
  }
  
sub _generate_interp_closure
   {
   my ( $lower, $upper, $key, $x_dn, $x_up ) = @_;

   my $interp = sub
      {
      my $k = shift();

      $lower = ref $lower ? $lower->_value($k) : $lower;
      $upper = ref $upper ? $upper->_value($k) : $upper;

      return _mx_plus_b( $key, $x_dn, $x_up, $lower, $upper );
      };

   return $interp;
   }

sub _mx_plus_b
  {
  my ( $x, $x_dn, $x_up, $y_dn, $y_up ) = @_;
  
  if ( $y_dn == $y_up )
     {
     return $y_dn;
     }

  my $slope     = ( $y_up - $y_dn ) / ( $x_up - $x_dn );
  my $intercept = $y_up - ( $slope * $x_up );
  my $y = $slope * $x + $intercept;

  return $y;
  }
  
sub _find_neighbors
   {
   my ( $array, $value, $min_index, $max_index ) = @_;
   
   if ( ! defined $min_index )
      {
      $min_index = 0;
      }

   if ( ! defined $max_index )
      {
      $max_index = $#{ $array };
      }
      
   my $array_size = $max_index - $min_index + 1;

   ## empty arrays return all undefs
   if ( $array_size < 1 )
      {
      return( undef, undef );
      }

   ## single knot functions  
   if ( $array_size == 1 )
      {
      return( 0, 0 );
      }

   ## direct hit on min
   if ( $value == $array->[$min_index] )
      {
      return( $min_index, $min_index );
      }

   ## direct hit on max
   if ( $value == $array->[$max_index] )
      {
      return( $max_index, $max_index );
      }

   ## left-wise out of bounds      
   if ( $value < $array->[$min_index] )
      {
      return( $min_index, $min_index );
      }

   ## right-wise out of bounds      
   if ( $value > $array->[$max_index] )
      {
      return( $max_index, $max_index );
      }
   
   ## no direct hits and not out of bounds, so must
   ## be between min and max
   if ( $array_size == 2 )
      {
      return( $min_index, $max_index );
      }
   
   ##                                   size:  3
   my $bottom_min = $min_index;             #  0 
   my $bottom_max = int( $array_size / 2 ); #  1
   my $top_min    = $bottom_max + 1;        #  2
   my $top_max    = $max_index;             #  2

   ## value is between the split point   
   if ( $value > $array->[$bottom_max] && $value < $array->[$top_min] )
      {
      return( $bottom_max, $top_min );
      }

   ## value is inside the lower half      
   if ( $value < $array->[$top_min] )
      {
      @_ = ( $array, $value, $bottom_min, $bottom_max );
      }
   ## value is inside the upper half
   else
      {
      @_ = ( $array, $value, $top_min, $top_max );
      }

   goto &_find_neighbors;
   }
   
sub _order_keys
   {
   my ( $self ) = @_;
   
   my @ordered_keys = sort { $a <=> $b } keys %{ $self->{'_data'} };
   
   $self->{'_keys'} = \@ordered_keys;
   }  

=head1 AUTHOR

Dan Boorstein, C<< <dan at boorstein.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-cpwlf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-CPWLF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::CPWLF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-CPWLF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-CPWLF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-CPWLF>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-CPWLF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Boorstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Math::CPWLF
