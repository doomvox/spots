package Spots::Rectangle::TestData;
#                                doom@kzsu.stanford.edu
#                                16 Apr 2019


=head1 NAME

Spots::Rectangle::TestData - TODO Perl extension for blah blah blah

=head1 SYNOPSIS

   use Spots::Rectangle::TestData ':all';

   foreach my $case ( @is_overlapping_cases ) {
     my $r1_coords = $case->{coords_1};
     my $r2_coords = $case->{coords_2};
     my $expected  = $case->{expected};

   }

   TODO

=head1 DESCRIPTION

Spots::Rectangle::TestData is a library with test cases available 
for export.

For example, it contains @is_overlapping_cases used in the
Spots::Rectangle tests in t/17-Spots-Rectangle-is_overlapping.t.

=head2 EXPORT

None by default.  Optionally:

=over

=cut

use 5.10.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use GD;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS, @EXPORT);
BEGIN {
 require Exporter;
 @ISA = qw(Exporter);
 %EXPORT_TAGS = ( 'all' => [
                            # TODO Add names of items to export here.
                            qw(
                                @is_overlapping_cases
                                @edge_distance_cases 
                                draw_cases
                             ) ] );
  @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
  @EXPORT = qw(  ); # items to export into callers namespace by default (avoid this!)
#  $DB::single = 1;
}

our $VERSION = '0.01';
my $DEBUG = 1;

=item @is_overlapping_cases

Test cases for t/17-Spots-Rectangle-is_overlapping.t an array of hases with keys:

    r1_coords
    r2_coords
    expected 
    name 

=cut 


our @is_overlapping_cases =
  (
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 100, 100, 200, 200 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is same as the first",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 100, 100, 250, 250 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second shares x1 point, but is taller and wider",
   },

   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 100, 80, 200, 220 ],
    expected  => 1,             # true, overlap
    name => "overlapped: second taller but shares left & right edges",
   },

   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 200, 200, 200, 200 ],
    expected  => 1,             # true, overlap
    name => "second is degenerate point on top of x2,y2",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 210, 210, 210, 210 ],
    expected  => 0,             # true, overlap
    name => "second is degenerate point but just near x2,y2",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 200, 200, 250, 250 ],
    expected  => 0,             # false, no-overlap
    name => "no-overlap: second is diagonally adjacent from first",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 50, 120, 120, 180 ],
    expected  => 1,             # true, overlap
    name => "overlap: second pushes through left side of first",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 190, 150, 300, 250 ],
    expected  => 1,             # true, overlap
    name => "overlap: second has upper-left corner over lower-right of first",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 120, 180, 150, 300 ],
    expected  => 1,             # true, overlap
    name => "overlap: second pushes through bottom of the first",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 100, 300, 200, 400 ],
    expected  => 0,             # false, no-overlap
    name => "no-overlap: second is below the first",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 250, 100, 450, 200 ],
    expected  => 0,             # false, no-overlap
    name => "no-overlap: second is to the right of 1st",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 100, 200, 200, 400 ],
    expected  => 1,             # true, overlap
    name => "overlap: top edge coincident, 2nd below 1st",
   },

   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 200, 200, 300, 300 ],
    expected  => 1,             # true, overlap
    name => "overlap: upper-right corner same as lower-left of 1st",
   },
   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 110, 110, 190, 190 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is inside of the first",
   },

   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 80, 80, 220, 220 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is outside of the first",
   },

   {
    r1_coords => [ 100, 100, 200, 200 ],
    r2_coords => [ 100, 100, 200, 200 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is same as the first",
   },
  );


=item @edge_distance_cases 

Test cases for 
   t/23-Spots-Rectangle-edge_distance.t

An array of hases with keys:

    r1_coords
    r2_coords
    expected 
    name 

the r*_coords are arefs of four integers, representing 
the upper-left and lower-right corners of the rectangle:

   [ x1, y1, x2, y2 ]


=cut 

our @edge_distance_cases =
  (
   {
    r1_coords => [ 10, 15, 20, 27 ],
    r2_coords => [ 35, 55, 50, 70 ],
    expected  => 31.8, # empirical, estimated around 30
    name => "second below and to the right (same as 1st 20-Spots-Rectangle-distance.t case)",
   },

   {
    r1_coords => [ 100, 150, 200, 270 ],
    r2_coords => [ 350, 550, 500, 700 ],
    expected  => 317.6, # empirical, estimated was 318.0
    name => "second below and to the right (100x)",
   },

   {
    r1_coords => [ 50, 75, 100, 135 ],
    r2_coords => [ 175, 275, 250, 350 ],
    expected  => 158.8, # empirical, estimated was 150
    name => "second below and to the right (50x)",
   },

   {
    r1_coords => [ 50, 75, 100, 135 ],
    r2_coords => [ 40, 275, 110, 350 ],
    expected  => 140.4, # empirical, estimated was 150
    name => "second roughtly below",
   },

   {
    r1_coords => [ 50, 75, 100, 135 ],
    r2_coords => [ 40, 135, 110, 210 ],
    expected  => 10.0, # empirical
    name => "second right on bottom edge, but because wider, we don't quite get 0",
   },


  );





=back 

=head2 utility routines

=over

=item 

=cut



=item draw_cases

=cut

# GD notes (*.org this?)
# font names string uses are barewords, maybe subs: gdMediumBoldFont, gdSmallFont, gdLargeFont gdLargeFont

sub draw_cases {
  my $cases      = shift || \@is_overlapping_cases;
  my $output_loc = shift || cwd();
  my $basename   = shift || 'rectangle_pairs';

  for my $i ( 0.. $#{ $cases } ) {
    my $case = $cases->[ $i ];
    my $r1_coords = $case->{ r1_coords };
    my $r2_coords = $case->{ r2_coords };
    my $expected  = $case->{ expected };
    my $case_name = $case->{ name };

    my ($r1x1, $r1y1, $r1x2, $r1y2)  = @{ $r1_coords };
    my ($r2x1, $r2y1, $r2x2, $r2y2) = @{ $r2_coords };

    my $suffix = sprintf( "%02d", $i );
    my $output_file = "$output_loc/$basename-$suffix.png";
    open my $imfh, '>', $output_file or die "$!";
    binmode $imfh;

    # create a new image
    my $im = new GD::Image( 500, 500 );
 
    # allocate some colors
    my $white = $im->colorAllocate( 255, 255, 255 );
    my $black = $im->colorAllocate(   0,   0,   0 );       
    my $red   = $im->colorAllocate( 255,   0,   0 );      
    my $blue  = $im->colorAllocate(   0,   0, 255 );

    my $r1_color = $blue;
    my $r2_color = $red;
 
#     # make the background transparent and interlaced
#     $im->transparent( $white );
#     $im->interlaced( 'true' );

    # offsets for point labels (left, right, up, down)
    my @r1_off = (-30, -15, 10, 10);
    my @r2_off = (-60, -25, 25, 25);

    my ($x1off, $y1off, $x2off, $y2off) = @r1_off;
    my ($xt, $yt); # text label location

    # Draw rectangles
    my $d = 12; # diameter of circles around points
    $im->setThickness( 3 );
    $im->rectangle( $r1x1, $r1y1, $r1x2, $r1y2, $r1_color );
    # draw circles around corner points
    $im->arc($r1x1,$r1y1,$d,$d,0,360,$r1_color);
    $im->arc($r1x2,$r1y2,$d,$d,0,360,$r1_color);

    ($xt, $yt) = ( $r1x1 + $x1off, $r1y1 + $y1off );
    $im->string( gdMediumBoldFont, $xt, $yt, "($r1x1, $r1y1)", $r1_color );

    ($xt, $yt) = ( $r1x2 + $x2off, $r1y2 + $y2off );
    $im->string( gdMediumBoldFont, $xt, $yt, "($r1x2, $r1y2)", $r1_color );

    ($x1off, $y1off, $x2off, $y2off) = @r2_off;
    $im->rectangle( $r2x1, $r2y1, $r2x2, $r2y2, $r2_color ); 
    # draw circles around corner points
    $d = 8; # diameter of circles around points
    $im->arc($r2x1,$r2y1,$d,$d,0,360,$r2_color);
    $im->arc($r2x2,$r2y2,$d,$d,0,360,$r2_color);


    ($xt, $yt) = ( $r2x1 + $x1off, $r2y1 + $y1off );
    $im->string( gdMediumBoldFont, $xt, $yt, "($r2x1, $r2y1)", $r2_color );

    ($xt, $yt) = ( $r2x2 + $x2off, $r2y2 + $y2off );
    $im->string( gdMediumBoldFont, $xt, $yt, "($r2x2, $r2y2)", $r2_color );

    ($xt, $yt) = ( 5, 430 );
    $im->string( gdMediumBoldFont, $xt, $yt, "$case_name: $expected", $black );

 
    # Convert the image to PNG and write it to file.
    print { $imfh } $im->png;
    close( $imfh );
  }
}







1;

=back

=head1 SEE ALSO

TODO Mention other useful documentation:

  o  related modules:  L<Module::Name>
  o  operating system documentation (such as man pages in UNIX)
  o  any relevant external documentation such as RFCs or standards
  o  discussion forum set up for your module (if you have it)
  o  web site set up for your module (if you have it)

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut
