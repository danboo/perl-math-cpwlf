package Math::CPWLF;

use warnings;
use strict;

use overload
   '&{}'    => sub { my $self = $_[0]; return _interp_closure( [ [ $self ] ] ) },
   fallback => 1;

=head1 NAME

Math::CPWLF - interpolation using nested continuous piecewise linear functions

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

C<Math::CPWLF> provides an interface for defining continuous piece-wise linear
functions by setting knots with x,y pairs.

   use Math::CPWLF;
    
   ## - define a line with a slope of 2
   ## - get the y value corresponding to an x of .5

   my $func = Math::CPWLF->new;

   $func->knot( 0 => 0 );
   $func->knot( 1 => 2 );
    
   my $y = $func->( 0.5 );   ## == 1
    
Functions can be used in multiple dimensions, by specifying a C<Math::CPWLF>
object as the y value of a knot.

   my $nested_func = Math::CPWLF->new;

   $nested_func->knot( 0 => 0 );
   $nested_func->knot( 1 => 3 );
   
   $func->knot( 2 => $nested_func );
   
   my $deep_y = $func->( 1.5 )( 0.5 );   ## == 1.75
   
As a convenience, you can specify arbitrarily deep knots by passing more than
two values two the C<knot> method.

   $func->knot( 2, 2 => 4 );   ## same as $nested_func->( 2 => 4);

If any of the intermediate knots do not exist they will be autovivified as
C<Math::CPWLF> objects, much like perl hashes.

   $func->knot( 3, 2 => 4 );   ## autovivify a new function

=head1 FUNCTIONS

=head2 new

Create a new C<Math::CPWLF> function with no knots.

=cut

sub new
  {
  my $self  = bless {}, shift();
  return $self;
  }
  
=head2 knot

=cut

sub knot
  {
  my $self = shift @_;
  
  if ( @_ == 2 )
     {
     my ( $key, $val ) = @_;
     $self->{'_data'}{$key} = $val;
     }
  elsif ( @_ > 2 )
     {
     my $key = shift @_;
     
     if ( ! defined $self->{'_data'}{$key} || ! ref $self->{'_data'}{$key} )
        {
        $self->{'_data'}{$key} = ( ref $self )->new;
        }
        
     $self->{'_data'}{$key}->knot(@_)
     
     }

  delete $self->{'_keys'};

  return $self;
  }
  
sub _interp_closure
   {
   my ( $stack ) = @_;
   
   my $interp = sub
      {
      my ($x_given) = @_;
      
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
               
            pop @{ $stack };

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
         
         my $return;
         
         for my $slice ( reverse @{ $stack } )
            {
               
            for my $node ( @{ $slice } )
               {

               my @line    = @{ $node }{ qw/ x_dn x_up y_dn y_up / };
               my $y_given = _mx_plus_b( $node->{'x_given'}, @line );
               
               $return = $y_given;
               
               if ( $node->{'into'} )
                  {
                  my $parent_node = $node->{'into'}[0];
                  my $neighbor    = $node->{'into'}[1];
                  $parent_node->{ $neighbor } = $y_given;
                  }

               }

            }
            
         return $return;
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
      die "Error: cannot interpolate with no knots";
      }
     
   my ( $x_dn_i, $x_up_i ) = _find_neighbors( $self->{'_keys'}, $key );
 
   my $x_dn = $self->{'_keys'}[ $x_dn_i ];
   my $x_up = $self->{'_keys'}[ $x_up_i ];

   my $y_dn = $self->{'_data'}{$x_dn};
   my $y_up = $self->{'_data'}{$x_up};

   return $x_dn, $x_up, $y_dn, $y_up;
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
