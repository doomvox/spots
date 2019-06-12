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

Spots::Rectangler is a module that that works with lists of
Spots::Rectangle objects.

(As of this writing, it just has a routine to draw diagrams of an
array of them.)

Note; there is also a draw_cases routine for diagramming pairs of
rectangles which is still in Spots::Rectangle::TestData located
in the project's t/lib.

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

use Spots::Config qw( $config );
use Spots::Rectangle;
use Spots::DB::Handle;
use Spots::Category;
use Spots::Herd;

=item new

Creates a new Spots::Rectangler object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item png_canvas_width   

The width of generated png in px, default 1800

=item png_canvas_height   

The height of generated png in px, default 900.

=item png_x_scale,  png_y_scale

Because you often want to scale-up when plotting rectangles: 
  defaults 1.5. and 1.5*3

=item png_dwg_offset

Need to offset the drawing from the top and left to leave 
room for labels and such.  Default: 30.

=item png_dwg_thickness

Width of lines in px. Default: 3.


=back

=cut

{ no warnings 'once'; $DB::single = 1; }

has png_canvas_width  => ( is => 'rw', isa => Num, default => $config->{ png_canvas_width }  || 1800 );
has png_canvas_height => ( is => 'rw', isa => Num, default => $config->{ png_canvas_height } || 900 );
has png_x_scale       => ( is => 'rw', isa => Num, default => $config->{ png_x_scale }       || 1.5 );
has png_y_scale       => ( is => 'rw', isa => Num, default => $config->{ png_y_scale }       || 1.5*3 );
has png_dwg_offset    => ( is => 'rw', isa => Num, default => $config->{ png_dwg_offset }    || 30 );
has png_dwg_thickness => ( is => 'rw', isa => Num, default => $config->{ png_dwg_thickness } || 3, );

# TODO 
# An idea to add type checking-- need a builder that creates an empty one?
# routines like draw_placed would use this by default, then.
# has rectangles    => ( is => 'rw', isa => ArrayRef[InstanceOf['Spots::Rectangle']], default => sub { ... } );

=item draw_placed

Spots::HomePage uses a datastructure (e.g. for "placed")
that's an array of Spots::Rectangle objects.

This is a routine to draw them, to facillitate debugging.

Example usage:

  $tangler->draw_placed( $placed );  

Alternately:

  $tangler->draw_placed( $placed, $out_loc, 'placed' );  

=cut

sub draw_placed {
  my $self       = shift;
  my $rects        = shift;
  my $output_loc   = shift || cwd();
  my $basename     = shift || 'rects';
  my $png_x_scale  = shift || $self->png_x_scale;
  my $png_y_scale  = shift || $self->png_y_scale;
  my $suffix       = '01'; # TODO uniquify?  Maybe with hh_mm?

  my $output_file = "$output_loc/$basename-$suffix.png";
  open my $imfh, '>', $output_file or die "$!";
  binmode $imfh;

  # create a new image
  my $png_canvas_width  = $self->png_canvas_width;
  my $png_canvas_height = $self->png_canvas_height;
  my $im = new GD::Image( $png_canvas_width, $png_canvas_height );

  my $colors = $self->generate_color_array( $im );
  my $black  = $im->colorAllocate(   0,   0,   0 );       

#     # make the background transparent and interlaced
#     $im->transparent( $white );
#     $im->interlaced( 'true' );

  my $png_dwg_thickness = $self->png_dwg_thickness;
  $im->setThickness( $png_dwg_thickness );

  # x&y offset for entire drawing (room to label points, etc)
  # my $png_dwg_offset = 30;
  my $png_dwg_offset = $self->png_dwg_offset;

  for my $r ( @{ $rects } ) {
    my @coords_raw = @{ $r->coords };
#     my ( $x1, $y1, $x2, $y2 ) = map{ $_ * $png_scale + $png_dwg_offset } @coords_raw;

#     # force y axis to be larger scale than x. HACK
#     $y1 *= 3;
#     $y2 *= 3;
    my ( $x1, $y1, $x2, $y2 ) = @coords_raw;
    $x1 = $x1 * $png_x_scale + $png_dwg_offset;
    $x2 = $x2 * $png_x_scale + $png_dwg_offset;
    $y1 = $y1 * $png_y_scale + $png_dwg_offset;
    $y2 = $y2 * $png_y_scale + $png_dwg_offset;

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

Allocates 350 colors.

Example usage: 

  my $im = new GD::Image( $png_canvas_width, $png_canvas_height );
  my $colors = $self->generate_color_array( $im );

=cut

### TODO refactor into two:
###      a routine that generates rgb values (arrays-of-arrays),
###      another that applies that to a $im via colorAllocate.
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
  # say STDERR "number of colors: " . scalar( @colors );  # just curious 
  # number of colors: 350
  return \@colors;
}


=item check_placed

Goes through the placed rectangles, looking for mistakes where
two rectangles overlap.  Returns a copy of the report, 
but if $DEBUG is on, it also reports directly to STDERR.

Example usage:

   my $report = $self->check_placed( $placed );

=cut

sub check_placed {
  my $self = shift;
  my $placed = shift;

  my $report = 'check_placed, called on: ' . $self->placed_summary( $placed );

  foreach my $i ( 0 .. $#{ $placed } ) { 
    foreach my $j ( $i+1 .. $#{ $placed } ) { 
      my $a = $placed->[ $i ];
      my $b = $placed->[ $j ];

      my $a_meta = $a->meta;
      my $b_meta = $b->meta;

      my $a_name = $a_meta->{cat_name};
      my $a_id   = $a_meta->{cat};

      my $b_name = $b_meta->{cat_name};
      my $b_id   = $b_meta->{cat};

      if( $a->is_overlapping( $b ) ) {  
        # report the problem
        my $a_coords = $a->coords;
        my $b_coords = $b->coords;

        my $mess;
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $a_id, $a_name, @{ $a_coords };
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $b_id, $b_name, @{ $b_coords };
        ($DEBUG) && say STDERR $mess, "\n";
        $report .= $mess;
      }
    }
  }
  return $report;
}

=item placed_summary

Generates a summary of an array of href-based objects.
Examines x1, y1, x2, y2, meta/cat, meta/cat_name, meta/metacat
And also reports width=x2-x1, height=y2-y1.

Returns a copy of the report.

=cut

sub placed_summary {
  my $self = shift;
  my $placed = shift || $self->placed;

  my $count = scalar(@{ $placed });
  my $class = ref( $placed->[0] );

  my $report = "$count objects of $class\n";
  foreach my $p ( @{ $placed } ) {
    my ($x1, $y1, $x2, $y2, $meta) = ( $p->x1, $p->y1, $p->x2, $p->y2, $p->meta );
    my ($cat, $cat_name, $metacat) = @{ $meta }{ 'cat', 'cat_name', 'metacat' };
    my ($width, $height) = ( $x2-$x1, $y2-$y1 );
    my $fmt = 
      qq{%4d: %-10s mc:%-4d [%6.1f,%6.1f]  [%6.1f,%6.1f]  %6.1f x %-6.1f \n};
    $report .= sprintf $fmt, 
      $cat, $cat_name, $metacat, $x1, $y1, $x2, $y2, $width, $height;
  }
  return $report;
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
