package Math::CPWLF;

use warnings;
use strict;

use Carp;
use Want;
use List::Util;

use overload
   fallback => 1,
   '&{}'    => sub
      {
      my $self = $_[0];
      return _top_interp_closure( $self, $self->{_opts} )
      };
      
=head1 NAME

Math::CPWLF - interpolation using nested continuous piece-wise linear functions

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

C<Math::CPWLF> provides an interface for defining continuous piece-wise linear
functions by setting knots with x,y pairs.

   use Math::CPWLF;
    
   $func = Math::CPWLF->new;

   $func->knot( 0 => 0 );             ## set the knot at f(0) equal to 0
   $func->knot( 1 => 2 );             ## set the knot at f(1) equal to 2
    
   $y = $func->( 0.5 );               ## interpolate f(0.5) ($y == 1)
    
Functions can be used in multiple dimensions, by specifying a C<Math::CPWLF>
object as the y value of a knot.

   $nested_func = Math::CPWLF->new;

   $nested_func->knot( 0 => 0 );
   $nested_func->knot( 1 => 3 );
   
   $func->knot( 2 => $nested_func );
   
   $deep_y = $func->( 1.5 )( 0.5 );   ## $deep_y == 1.75
   
As a convenience, you can specify arbitrarily deep knots by passing more than
two values two the C<knot> method.

   $func->knot( 2, 2 => 4 );          ## same as $nested_func->( 2 => 4);

If any of the intermediate knots do not exist they will be autovivified as
C<Math::CPWLF> objects, much like perl hashes.

   $func->knot( 3, 2 => 4 );          ## autovivify top level f(3)

=head1 FUNCTIONS

=head2 new

Construct a new C<Math::CPWLF> function with no knots, and the default out of
bounds behavior.

   my $func = Math::CPWLF->new;
   
Optional parameters:

=over 4

=item * oob

Controls how a function behaves when a given x value is out of bounds of the
current minimum and maximum knots. If a function defines an C<oob> method in
its constructor, that method is also used for any nested functions that were
not explicitly constructed with their own C<oob> methods.

=over 4

=item * C<die> - Throw an exception (default).

=item * C<extrapolate> - Perform a linear extrapolation using the two nearest knots.

=item * C<level> - Return the y value of the nearest knot.

=item * C<undef> - Return undef.

=back

Construct an instance that returns C<undef> or empty list when the requested x
is out of bounds:

   my $func = Math::CPWLF->new( oob => 'undef' );

=back

=cut

sub new
  {
  my $self        = bless {}, shift();
  my %opts        = @_;
  $self->{_opts}  = \%opts;
  return $self;
  }
  
=head2 knot

This instance method adds a knot with the given x,y values.

   $func->knot( $x => $y );
  
Knots can be specified at arbitrary depth and intermediate knots will autovivify
as needed. There are two alternate syntaxes for setting deep knots. The first
involves passing 3 or more values to the C<knot()> call, where the last value
is the y value and the other values are the depth-ordered x values:

   $func->knot( $x1, $x2, $x3 => $y );
   
The other syntax is a bit more hash-like in that it separates the x values. Note
that it starts with invoking the C<knot()> method with no arguments.

   $func->knot->($x1)($x2)( $x3 => $y );

=cut

sub knot
  {
  my $self = shift @_;
  
  ## caller intends to use hash-like multi-dimensional syntax
  ## $f->knot->(1)(2)( 3 => 4 );
  if ( @_ == 0 )
     {
     return sub
        {
        $self->knot( @_ );
        };
     }
  ## caller is in the middle of using hash-like multi-dimensional syntax
  elsif ( @_ == 1 )
     {
     my $key = shift;

     if ( ! defined $self->{'_data'}{$key} || ! ref $self->{'_data'}{$key} )
        {
        $self->{'_data'}{$key} = ( ref $self )->new;
        }

     return sub
        {
        $self->{'_data'}{$key}->knot( @_ );
        };
     }
  ## args are an x,y pair
  elsif ( @_ == 2 )
     {
     my ( $key, $val ) = @_;
     $key += 0;
     $self->{'_data'}{$key} = $val;
     }
  ## caller is using bulk multi-dimensional syntax
  ## $f->knot( 1, 2, 3 => 4 );
  elsif ( @_ > 2 )
     {
     my $key = shift;
     
     $key += 0;
     
     if ( ! defined $self->{'_data'}{$key} || ! ref $self->{'_data'}{$key} )
        {
        $self->{'_data'}{$key} = ( ref $self )->new;
        }
        
     $self->{'_data'}{$key}->knot(@_)
     
     }

  delete $self->{'_keys'};

  return $self;
  }
  
sub _top_interp_closure
   {
   my ( $func, $opts ) = @_;
   
   my $interp = sub
      {
      my ( $x_given ) = @_;

      $x_given += 0;

      my ($x_dn, $x_up, $y_dn, $y_up) =
         $func->_neighbors($x_given, $opts);
      
      return _nada() if ! defined $x_dn;

      my $node =
         {
         x_given => $x_given,
         x_dn    => $x_dn,
         y_dn    => $y_dn,
         x_up    => $x_up,
         y_up    => $y_up,
         };

      my @slice = ( $node );
      my @tree  = ( \@slice );

      return ref $y_dn || ref $y_up ? _nested_interp_closure( \@tree, $opts )
                                    : _reduce_tree( \@tree )
      };
   
   }
  
sub _nested_interp_closure
   {
   my ( $tree, $opts ) = @_;
   
   my $interp = sub
      {
      my ($x_given) = @_;
      
      $x_given += 0;
      
      my @slice;
      my $make_closure;
      
      for my $node ( @{ $tree->[-1] } )
         {
            
         for my $y_pos ( 'y_dn', 'y_up' )
            {
            
            next if ! ref $node->{$y_pos};
            
            my ($x_dn, $x_up, $y_dn, $y_up) =
               $node->{$y_pos}->_neighbors($x_given, $opts);
            
            return _nada() if ! defined $x_dn;
         
            $make_closure = ref $y_dn || ref $y_up;
               
            push @slice,
               {
               x_given => $x_given,
               x_dn    => $x_dn,
               y_dn    => $y_dn,
               x_up    => $x_up,
               y_up    => $y_up,
               into    => \$node->{$y_pos},
               };

            }

         }
         
      push @{ $tree }, \@slice;
      
      return $make_closure ? _nested_interp_closure( $tree, $opts )
                           : _reduce_tree( $tree )
      
      };

   return $interp;   
   }

## converts the final tree of curried line segments and x values to the final
## y value
sub _reduce_tree
   {
   my ($tree) = @_;

   for my $slice ( reverse @{ $tree } )
      {
         
      for my $node ( @{ $slice } )
         {

         my @line = grep defined, @{ $node }{ qw/ x_dn x_up y_dn y_up / };
         
         my $y_given = _mx_plus_b( $node->{'x_given'}, @line );
         
         return $y_given if ! $node->{'into'};

         ${ $node->{'into'} } = $y_given;

         }

      }
      
   }

## used to handle 'undef' oob exceptions
##   - returns a reference to itself in CODEREF context
##   - else returns undef   
sub _nada
   {
   return want('CODE') ? \&_nada : ();
   }   
   
{

my $default_opts =
   {
   oob => 'die',
   };   

## - merges the options, priority from high to low is:
##    - object
##    - inherited
##    - defaults
sub _merge_opts
   {
   my ($self, $inherited_opts) = @_;
   
   my %opts;
   
   for my $opts ( $self->{_opts}, $inherited_opts, $default_opts )
      {
      for my $opt ( keys %{ $opts } )
         {
         next if defined $opts{$opt};
         $opts{$opt} = $opts->{$opt};
         }
      }
   
   return \%opts;
   }
   
}

## - locate the neighboring x and y pairs to the given x values
## - handles oob exceptions
## - handles direct hits
## - handles empty functions
sub _neighbors
   {
   my ($self, $key, $opts) = @_;
  
   if ( ! exists $self->{'_keys'} )
      {
      $self->_order_keys;
      $self->_index_keys;
      }
     
   if ( ! @{ $self->{'_keys'} } )
      {
      die "Error: cannot interpolate with no knots";
      }

   my ( $x_dn_i, $x_up_i, $oob );
      
   if ( exists $self->{'_index'}{$key} )
      {
      $x_dn_i     = $self->{'_index'}{$key};
      $x_up_i     = $x_dn_i;
      }
   elsif ( $key < $self->{'_keys'}[0] )
      {
      $x_dn_i = 0;
      $x_up_i = 0;
      $oob    = 1;
      }
   elsif ( $key > $self->{'_keys'}[-1] )
      {
      $x_dn_i = -1;
      $x_up_i = -1;
      $oob    = 1;
      }
   else
      {
      ( $x_dn_i, $x_up_i ) = do
         {
         my $min = 0;
         my $max = $#{ $self->{'_keys'} };
         _binary_search( $self->{'_keys'}, $key, $min, $max );
         };
      }
   
   if ( $oob )
      {
      my $merge_opts = $self->_merge_opts( $opts );
      if ( $merge_opts->{oob} eq 'die' )
         {
         Carp::confess "Error: given X ($key) was out of bounds of"
            . " function min or max";
         }
      elsif ( $merge_opts->{oob} eq 'extrapolate' )
         {
         if ( $key < $self->{_keys}[0] )
            {
            $x_up_i = List::Util::min( $#{ $self->{_keys} }, $x_up_i + 1 );
            }
         elsif ( $key > $self->{_keys}[-1] )
            {
            $x_dn_i = List::Util::max( 0, $x_dn_i - 1 );
            }
         }
      elsif ( $merge_opts->{oob} eq 'level' )
         {
         }
      elsif ( $merge_opts->{oob} eq 'undef' )
         {
         return;
         }
      else
         {
         Carp::confess "Error: invalid oob option ($merge_opts->{oob})";
         }
      }

   my $x_dn = $self->{'_keys'}[ $x_dn_i ];
   my $x_up = $self->{'_keys'}[ $x_up_i ];

   my $y_dn = $self->{'_data'}{$x_dn};
   my $y_up = $self->{'_data'}{$x_up};
   
   return $x_dn, $x_up, $y_dn, $y_up;
   }

## converts a given x value and two points that define a line
## to the corresponding y value
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

## vanilla binary search algorithm used to locate a given x value
## that is within the defined range of the function  
sub _binary_search
   {
   my ( $array, $value, $min_index, $max_index ) = @_;
   
   my $array_size = $max_index - $min_index + 1;
   
   if ( $array_size > 2 )
      {

      ##                                                        size:  3 20
      my $mid_index  = $min_index + int( ( $array_size - 1 ) / 2 ); #  1  9
      
      ## value is inside the lower half      
      if ( $value <= $array->[$mid_index] )
         {
         $_[3] = $mid_index;
         }
      ## value is inside the upper half
      else
         {
         $_[2] = $mid_index;
         }

      goto &_binary_search;

      }
   elsif ( $array_size > 0 )
      {

      return( $min_index, $max_index );

      }
   else
      {
      return( undef, undef );
      }

   }
   
## - called on the first lookup after a knot has been set   
## - caches an array of ordered x values
sub _order_keys
   {
   my ( $self ) = @_;
   
   my @ordered_keys = sort { $a <=> $b } keys %{ $self->{'_data'} };
   
   $self->{'_keys'} = \@ordered_keys;
   }

## - called on the first lookup after a knot has been set   
## - creates an index mapping knot x values to their ordered indexes
sub _index_keys
   {
   my ( $self ) = @_;

   delete $self->{'_index'};
   for my $i ( 0 .. $#{ $self->{'_keys'} } )
      {
      $self->{'_index'}{ $self->{'_keys'}[$i] } = $i;
      }
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
