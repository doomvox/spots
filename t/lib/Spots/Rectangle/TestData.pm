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

        draw_cases
  ) ] );
  # The above allows declaration	use Spots::Rectangle::TestData ':all';

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
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 10, 10, 20, 20 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is same as the first",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 10, 10, 25, 25 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second shares x1 point, but is taller and wider",
   },

   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 10, 8, 20, 22 ],
    expected  => 1,             # true, overlap
    name => "overlapped: second taller but shares left & right edges",
   },

   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 20, 20, 20, 20 ],
    expected  => 1,             # true, overlap
    name => "second is degenerate point on top of x2,y2",
   },

   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 21, 21, 21, 21 ],
    expected  => 0,             # true, overlap
    name => "second is degenerate point but just near x2,y2",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 20, 20, 25, 15 ],
    expected  => 0,             # false, no-overlap
    name => "no-overlap: second is diagonally adjacent from first",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 5, 12, 12, 18 ],
    expected  => 1,             # true, overlap
    name => "overlap: second pushes through left side of first",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 19, 15, 30, 25 ],
    expected  => 1,             # true, overlap
    name => "overlap: second has upper-left corner over lower-right of first",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 12, 18, 15, 30 ],
    expected  => 1,             # true, overlap
    name => "overlap: second pushes through bottom of the first",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 10, 30, 20, 40 ],
    expected  => 0,             # false, no-overlap
    name => "no-overlap: second is below the first",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 25, 10, 45, 20 ],
    expected  => 0,             # false, no-overlap
    name => "no-overlap: second is to the right of 1st",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 10, 20, 20, 40 ],
    expected  => 1,             # true, overlap
    name => "overlap: top edge coincident, 2nd below 1st",
   },

   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 20, 20, 30, 30 ],
    expected  => 1,             # true, overlap
    name => "overlap: upper-right corner same as lower-left of 1st",
   },
   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 11, 11, 19, 19 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is inside of the first",
   },

   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 8, 8, 22, 22 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is outside of the first",
   },

   {
    r1_coords => [ 10, 10, 20, 20 ],
    r2_coords => [ 10, 10, 20, 20 ],
    expected  => 1,             # true, overlap
    name => "totally overlapped: second is same as the first",
   },
  );

=back 

=head2 utility routines

=over

=item 

=cut



=item draw_cases

=cut

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
    my $im = new GD::Image( 300, 300 );
 
    # allocate some colors
    my $white = $im->colorAllocate( 255, 255, 255 );
    my $black = $im->colorAllocate(   0,   0,   0 );       
    my $red   = $im->colorAllocate( 255,   0,   0 );      
    my $blue  = $im->colorAllocate(   0,   0, 255 );
 
    # make the background transparent and interlaced
    $im->transparent( $white );
    $im->interlaced( 'true' );

    # Draw rectangles
    $im->rectangle( $r1x1, $r1y1, $r1x2, $r1y2, $blue );
    $im->rectangle( $r2x1, $r2y1, $r2x2, $r2y2, $black ); 
 
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
