# Perl test file, can be run like so:
#   perl 30-Spots-Rectangler-draw_placed.t
#          doom@kzsu.stanford.edu     2019/06/10

use 5.10.0;
use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Carp;
use Data::Dumper::Names;
use File::Path         qw( mkpath );
use File::Basename     qw( fileparse basename dirname );
use File::Copy         qw( copy move );
use autodie            qw( :all mkpath copy move ); # system/exec along with open, close, etc
use Cwd                qw( cwd abs_path );
use Env                qw( HOME );
use List::Util         qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils    qw( zip uniq );
use String::ShellQuote qw( shell_quote_best_effort );

use Test::More;

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::Rectangler', );
#  use_ok( 'Spots::HomePage' );
  use_ok( 'Spots::HomePage::Layout::MetacatsFanout' );
  use lib ("$Bin/lib");
  use_ok( 'Spots::Rectangle::TestData', ':all' );  # draw_placed
  use_ok( 'Spots::Test::DB::Init', );
}

ok(1, "Traditional: If we made it this far, we're ok.");

my $tidb = Spots::Test::DB::Init->new();
my $tp = $tidb->test_prefix;
my $tNN = 't' . $tp;

my $output_directory = "$Bin/out/$tNN";
mkpath( $output_directory ) unless -d $output_directory;

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "draw_placed";
   my $test_name = "Testing $subname";

   my $placed = define_placed();

   my %tangler_args = (
                    png_canvas_width  => 1800,
                    png_canvas_height => 900,
                    png_x_scale       => 1.5,
                    png_y_scale       => 1.5*3,
                    png_dwg_offset    => 30,
                    png_dwg_thickness => 3,
                   );
   my $tangler = Spots::Rectangler->new( \%tangler_args );

   chdir( $output_directory );
   my @png_files = glob("*.png");
   unlink @png_files if scalar( @png_files ) < 5;
   ok( not( glob("*.png") ),
      "Verifying clean slate: no png files here");

   $tangler->draw_placed( $placed );  # creates a png in current directory

   @png_files = glob("*.png");
   is( scalar( @png_files ), 1, "$test_name: only one png file created" );
   my $png_file = $png_files[0];

   my $size = -s $png_file;
   my $check_size = 1000;
   cmp_ok( $size, '>', $check_size,
           "$test_name:  created png bigger than $check_size " ); 

   # TODO  *could* use some of my wonky box detection code to scrape rectangles
   #       out of it... TODO clean that up, deploy it to cpan, 

   # TODO Check the generated file, if you like it, make a copy in the "src" tree,
   #      do a binary comparison of that to the generated file.

 }

{  my $subname = "draw_placed";
   my $test_name = "Testing $subname larger scaling";

   my $placed = define_placed();

   my %tangler_args = (
                    png_canvas_width  => 1800,
                    png_canvas_height => 900,
                    png_x_scale       => 4,  # was 1.5
                    png_y_scale       => 16, # was 1.5*3,
                    png_dwg_offset    => 30,
                    png_dwg_thickness => 3,
                   );
   my $tangler = Spots::Rectangler->new( \%tangler_args );

#    $tangler->png_x_scale( 4 );
#    $tangler->png_y_scale( 16 );

   # switch to an alternate (subdirectory?)
   my $alt_output_directory = "$Bin/out/$tNN/2nd";
   mkpath( $alt_output_directory ) unless -d $alt_output_directory;

   chdir( $alt_output_directory );
   my @png_files = glob("place*.png");
   unlink @png_files  if scalar( @png_files ) < 5;
   ok( not( glob("*.png") ),
      "Verifying clean slate: no png files here, either");

   $tangler->draw_placed( $placed, $alt_output_directory, 'place_mat' );  

    @png_files = glob("*.png");
    is( scalar( @png_files ), 1, "$test_name: only one png file created" );
    my $png_file = $png_files[0];
    # say Dumper( \@png_files );

    my $size = -s $png_file;
    my $check_size = 1000;
    cmp_ok( $size, '>', $check_size,
            "$test_name:  created png bigger than $check_size " ); 

}

done_testing();


=item define_placed

Returns a short aref of Rectangle objects, much 
like the rectangles "placed" in a test like:

  52-Spots-HomePage-generate_layout_metacats_fanout.t

=cut 

sub define_placed {

  my $placed = [
          bless( {
                   'x1' => 4,
                   'center' => [
                                 49,
                                 '4.62'
                               ],
                   'coords' => [
                                 4,
                                 0,
                                 94,
                                 '9.24'
                               ],
                   'y2' => '9.24',
                   'x2' => 94,
                   'meta' => {
                               'cat_name' => 'oakland',
                               'metacat' => 2,
                               'cat' => 1,
                               'metacat_name' => 'local'
                             },
                   'y_weight' => '6.5',
                   'y1' => 0
                 }, 'Spots::Rectangle' ),
          bless( {
                   'x2' => 94,
                   'meta' => {
                               'metacat' => 2,
                               'cat_name' => 'sf',
                               'cat' => 2,
                               'metacat_name' => 'local'
                             },
                   'y_weight' => '6.5',
                   'y1' => '9.74',
                   'x1' => 4,
                   'y2' => '18.98',
                   'coords' => [
                                 4,
                                 '9.74',
                                 94,
                                 '18.98'
                               ],
                   'center' => [
                                 49,
                                 '14.36'
                               ]
                 }, 'Spots::Rectangle' ),
          bless( {
                   'coords' => [
                                 4,
                                 '19.48',
                                 94,
                                 '23.44'
                               ],
                   'meta' => {
                               'metacat' => 10,
                               'cat_name' => 'jobs',
                               'metacat_name' => 'working',
                               'cat' => 3
                             },
                   'y_weight' => '6.5'
                 }, 'Spots::Rectangle' )
        ];
  return $placed;
}
