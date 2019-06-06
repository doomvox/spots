package Spots::Rectangler;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::Rectangler - Spots::Rectangler deals with a bunch of Spots::Rectangles

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::Rectangler;
   my $tangler = Spots::Rectangler->new();

   $tangler->draw_placed( $placed );  # creates a png in current directory


=head1 DESCRIPTION

Spots::Rectangler is a module that that manages a bunch of Spots::Rectangle objects.

(As of this writing, it just has a routine to draw diagrams of an array of them.)

Note; there is also a draw_cases routine for diagramming pairs of rectangles
which is still in Spots::Rectangle::TestData located in the project's t/lib.


=head1 METHODS

=over

=cut

use 5.10.0;
use Carp;
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use autodie         qw( :all mkpath copy move ); # system/exec along with open, close, etc
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );
use String::ShellQuote qw( shell_quote );

use GD;

use Spots::Rectangle;
use Spots::DB::Handle;
use Spots::Category;
use Spots::Herd;

=item new

Creates a new Spots::Rectangler object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item canvas_width   

The width of generated png in px, default 1800

=item canvas_height   

The height of generated png in px, default 900.

=item scale 

Because you often want to scale-up when plotting rectangles: default 1.5.

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );

{ no warnings 'once'; $DB::single = 1; }

has canvas_width  => ( is => 'rw', isa => Num, default => 1800 );
has canvas_height => ( is => 'rw', isa => Num, default => 900 );
has scale         => ( is => 'rw', isa => Num, default => 1.5 );

=item draw_placed

Spots::HomePage uses a datastructure (e.g. for "placed") that's 
an array of Spots::Rectangle objects.  

This is a routine to draw them, to facillitate debugging.

Example usage:

  draw_placed( $placed, $output_loc, $basename );

=cut

sub draw_placed {
  my $self       = shift;
  my $rects      = shift;
  my $output_loc = shift || cwd();
  my $basename   = shift || 'rects';
  my $scale      = shift || $self->scale;
  my $suffix     = '01'; # TODO uniquify?  Maybe with hh_mm?

  my $output_file = "$output_loc/$basename-$suffix.png";
  open my $imfh, '>', $output_file or die "$!";
  binmode $imfh;

  # create a new image
  my $canvas_width  = $self->canvas_width;
  my $canvas_height = $self->canvas_height;
  my $im = new GD::Image( $canvas_width, $canvas_height );

  my $colors = $self->generate_color_array( $im );
  my $black  = $im->colorAllocate(   0,   0,   0 );       

#     # make the background transparent and interlaced
#     $im->transparent( $white );
#     $im->interlaced( 'true' );

  $im->setThickness( 3 );

  # x&y offset for entire drawing (room to label points, etc)
  my $dwg_off = 30;

  for my $r ( @{ $rects } ) {
    my @coords_raw = @{ $r->coords };
    my ( $x1, $y1, $x2, $y2 ) = map{ $_ * $scale + $dwg_off } @coords_raw;
    # force y axis to be larger scale than x.
    $y1 *= 3;
    $y2 *= 3;
    my $cat = $r->cat;

    # use original "raw" values for point labels:
    my ( $lx1, $ly1, $lx2, $ly2 ) = @coords_raw;

    # my $color = $black;
    my $color = pop( @{ $colors } );
    
    # offsets for point labels (left, right, up, down)
    my @off = (-30, -15, 10, 10);

    my ($x1off, $y1off, $x2off, $y2off) = @off;
    my ($xt, $yt); # text label location

    # Draw rectangles
    $im->rectangle( $x1, $y1, $x2, $y2, $color );
    # draw circles around corner points
    my $d = 12; # diameter of circles around points
    $im->arc($x1,$y1,$d,$d,0,360,$color);
    $im->arc($x2,$y2,$d,$d,0,360,$color);

    ($xt, $yt) = ( $x1 + $x1off, $y1 + $y1off );
    $im->string( gdMediumBoldFont, $xt, $yt, "$cat: ($lx1, $ly1)", $color );
    ($xt, $yt) = ( $x2 + $x2off, $y2 + $y2off );
    $im->string( gdMediumBoldFont, $xt, $yt, "$cat: ($lx2, $ly2)", $color );

  }
  # Convert the image to PNG and write it to file.
  print { $imfh } $im->png;
  close( $imfh );
}


=item generate_color_array

Given a GD image object ($im), allocates a sequence of
semi-randomly choosed colors and returns an aref to a list of
them.

The colors are choosen to have some contrast against a black
background and to differ significantly from each other.

=cut

sub generate_color_array {
  my $self = shift;
  my $im = shift;

  # allocate some colors
  my $black     = $im->colorAllocate(   0,   0,   0 );       
  my $red       = $im->colorAllocate( 255,   0,   0 );      
  my $blue      = $im->colorAllocate(   0, 255,   0 );
  my $green     = $im->colorAllocate(   0,   0, 255 );
  my $purple    = $im->colorAllocate( 233, 255,   0 );      
  my $bluegreen = $im->colorAllocate(   0, 255, 233 );
  my $redgreen  = $im->colorAllocate( 200,   0, 255 );
  my $bleh      = $im->colorAllocate( 200, 255, 200 );

  my @colors = ( $black, $red, $blue, $green, $purple, $bluegreen, $bleh );

  my @deltas = ( 0, 0, 33, 33*2, 33*3, 33*4, 33*5 );
  my @r_d = shuffle( @deltas );
  my @g_d = shuffle( @deltas );
  my @b_d = shuffle( @deltas );

  my @new_colors;
  foreach my $r_d ( @r_d ) {
    foreach my $g_d ( @g_d ) {
      foreach my $b_d ( @b_d ) {
        my ( $r, $g, $b ) = ( 233, 233, 233 );
        $r -= $r_d unless $r < $r_d;
        $b -= $b_d unless $b < $b_d;
        $g -= $g_d unless $g < $g_d;

        push @new_colors, 
          $im->colorAllocate( $r, $b, $g );
      }
    }
  }
  push @colors, shuffle @new_colors;
  say STDERR "number of colors: " . scalar( \@colors );  # just curious 
  return \@colors;
}




=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
06 Jun 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
