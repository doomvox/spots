package Spots::Rectangle;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::Rectangle - grid-aligned rectangles

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::Rectangle;
   my $rect   = Spots::Rectangle->new({ 
                coords => [ $x1, $y1, $x2, $y2 ] 
              });  

   my $coords = $rect->coords;
   my $x1 = $coords->[0];

   my $x1 = $rect->x1 

   if( not( $rect_a->is_overlapping( $rect_b ) ) ) {
      say "Rectangles A and B do not overlap"; 
   }                                           



   my $rect_a = Spots::Rectangle->new({ 
                coords => [ 10, 15, 20, 27 ] 
              });  
   my $rect_b = Spots::Rectangle->new({ 
                coords => [ 35, 55, 50, 70 ] 
              });  

  my $center_to_center_distance = $rect_a->distance( $rect_b );






=head1 DESCRIPTION

Spots::Rectangle is a class for representing a simple,
grid-aligned rectangle (as is often used in software UIs)
as two points:


                                x         
    o-------------------------------->    
    |                                     
    |        (x1, y1)                     
    |         o----------.                
    |         |          |                
    |         |          |                
    |         |          |                
    |         .----------o                
 y  |                  (x2, y2)           
    | 
    v                                     
                                         
=head1 METHODS

=over

=cut

use 5.10.0;
use Carp;
use Data::Dumper;

=item new

Creates a new Spots::Rectangle object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item coords 

An array ref of the coordinates of the rectangle, x1, y1, x2, y2.

=item x1, y1, x2, y2

Individidual coordinate fields, set automatically if coords is 
defined when object is created.

=back

=cut

has coords => ( is => 'ro', isa => ArrayRef, builder => sub{ [] } );  

has x1 => ( is => 'ro', isa => Int, lazy => 1, builder=>'build_x1' );
has y1 => ( is => 'ro', isa => Int, lazy => 1, builder=>'build_y1' );
has x2 => ( is => 'ro', isa => Int, lazy => 1, builder=>'build_x2' );
has y2 => ( is => 'ro', isa => Int, lazy => 1, builder=>'build_y2' );

has y_weight => ( is => 'ro', isa => Int, default => 10 );  # 1 rem =~ 10 px , used by "distance" calculation

# has y_weight => ( is => 'ro', isa => Int, default => 1 );  # comparing rem to px

has center => ( is => 'ro', isa => ArrayRef, lazy => 1, builder=>'calculate_center' ); 

sub build_x1 {
  my $self = shift;
  my $coords = $self->coords;
  my $x1 =  $coords->[0];
  return $x1;
}

sub build_y1 {
  my $self = shift;
  my $coords = $self->coords;
  my $y1 =  $coords->[1];
  return $y1;
}

sub build_x2 {
  my $self = shift;
  my $coords = $self->coords;
  my $x2 =  $coords->[2];
  return $x2;
}

sub build_y2 {
  my $self = shift;
  my $coords = $self->coords;
  my $y2 =  $coords->[3];
  return $y2;
}

{ no warnings 'once'; $DB::single = 1; }


=item calculate_center

=cut

sub calculate_center {
  my $self = shift;
  my $x1 = $self->x1;
  my $x2 = $self->x2;
  my $y1 = $self->y1;
  my $y2 = $self->y2;

  my $x = ($x2-$x1)/2 + $x1;
  my $y = ($y2-$y1)/2 + $y1;

  return [$x, $y];
}



=item distance


=cut

sub distance {
  my $self  = shift;
  my $other = shift;
  my $y_weight = shift || $self->y_weight;
  
  my ($xs, $ys) = @{ $self->center };
  my ($xo, $yo) = @{ $other->center };

  my $distance = sqrt( ($xs - $xo)**2 + ($ys*$y_weight - $yo*$y_weight)**2 );
  return $distance;
}

=item is_overlapping

The non-overlap condition for two grid-aligned rectangles

       (Ax1 < Bx1  && Ax2 < Bx2)  
   ||  (Ax1 > Bx1  && Ax2 > Bx2)                         
   ||  (Ay1 < By1  && Ay2 < By2)  
   ||  (Ay1 > By1  && Ay2 > By2)                         

=cut

sub is_overlapping {
  my $self = shift;
  my $b    = shift;
  my $a    = $self; # alias better?

  my $non_overlap = 
     ($a->x1 < $b->x1  && $a->x2 < $b->x2)
  || ($a->x1 > $b->x1  && $a->x2 > $b->x2)
  || ($a->y1 < $b->y1  && $a->y2 < $b->y2)
  || ($a->y1 > $b->y1  && $a->y2 > $b->y2);

  my $overlap = not( $non_overlap );
  return $overlap;
}







=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
07 Apr 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
