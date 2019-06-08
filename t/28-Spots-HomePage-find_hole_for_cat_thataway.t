# Perl test file, can be run like so:
#   perl 28-Spots-HomePage-find_hole_for_cat_thataway.t
#          doom@kzsu.stanford.edu     2019/05/16 11:09:32

use 5.10.0;
use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Carp;
use Data::Dumper;
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

our $test_lib;
BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
#  use_ok( 'Spots::HomePage' );
  use_ok( 'Spots::HomePage::Layout::MetacatsFanout' );
  $test_lib = "$Bin/lib/";
}

use lib ($test_lib);
use Spots::Rectangle::TestData qw(:all);  # draw_placed
use Spots::Rectangler;

ok(1, "Traditional: If we made it this far, we're ok.");

#my $output_directory = "$Bin/dat/t28";
my $output_directory = "$Bin/src/t28";
mkpath( $output_directory ) unless -d $output_directory;

{ no warnings 'once'; $DB::single = 1; }

# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "find_hole_for_cat_thataway";
   my $test_name = "Testing $subname direction 'e'";
   my $direction = 'e';
   $test_name .= " direction $direction";
   
   my $base = "mah_moz_ohm";  # for 28-*.t, unused at present
   # TODO need way to reinitializing the spots_test db to known state 
#   my $obj = Spots::HomePage->new(
   my $obj = Spots::HomePage::Layout::MetacatsFanout->new(
                               output_basename  => $base,
                               output_directory => $output_directory,
                               db_database_name => 'spots_test',
                              );

   my ($cat, $placed) = define_params();
   $obj->placed_summary( $placed );

#   draw_placed( $placed, $output_directory, "placed" );
   my $tangler = Spots::Rectangler->new();
   $tangler->draw_placed( $placed, $output_directory, "placed" );  # creates a png in current directory

   # begins next door to a given start rectangle: 
   my ($x_trial, $y_trial) = ( 124, 0 );

   my $adds = $obj->find_hole_for_cat_thataway( $direction, $cat, $x_trial, $y_trial, $placed );

   say STDERR Dumper( $adds );
  # $expected = [
  #           124,
  #           0
  #         ];

   my $x1_result = $adds->[0];  # 124
   my $y1_result = $adds->[1];  # 0

   # # Works because placed is a vertical column with x1=5
   # my $right_side = max map{ $_->{x2} } @{ $placed };

   # But the cat we're trying to position has:
   #       'height' => '21.5',
   # So it fits in above the third element in the $placed list

   my $effective_right_side = max( $placed->[0]->{x2}, $placed->[1]->{x2} );

   is( $y1_result, $y_trial, "$test_name: going 'e' should leave y value unchanged.");
   cmp_ok( $x1_result, '>=', $effective_right_side, "$test_name: should be far enough over to miss previous rects.");   
 }

{  my $subname = "find_hole_for_cat_thataway";
   my $test_name = "Testing $subname";
   my $direction = 's';
   $test_name .= " direction $direction";

   # This test (probably) won't use these settings, another test like it might
   my $base = "mah_moz_ohm";
   my $output_directory =  "...";  ### TODO a scratch location in test tree 
   mkpath( $output_directory ) unless -d $output_directory;

   # TODO need way to reinitializing the spots_test db to known state 
#   my $obj = Spots::HomePage->new(
   my $obj = Spots::HomePage::Layout::MetacatsFanout->new(
                               output_basename  => $base,
                               output_directory => $output_directory,
                               db_database_name => 'spots_test',
                              );

   my ($cat, $placed) = define_params();

   $obj->placed_summary( $placed );

   # begins just below a given start rectangle: 
   my ($x_trial, $y_trial) = ( 5, 12.1 );

   my $adds = $obj->find_hole_for_cat_thataway( $direction, $cat, $x_trial, $y_trial, $placed );
   say STDERR Dumper( $adds );

   my $x_result = $adds->[0];  # 5
   my $y_result = $adds->[1];  # 27.8

   my $lower_bound = max map{ $_->y2 } @{ $placed };

   is( $x_result, $x_trial, "$test_name: going 's' should leave x value unchanged.");
   cmp_ok( $y_result, '>=', $lower_bound, "$test_name: down below the three previously placed.");   
 }




=item define_params

Define some data structures used as paramters to "find_hole_for_cat_thataway".

Example usage:

   my ($cat, $placed) = define_params();

=cut

sub define_params {
  my $spots = [
    {
        'label'   => 'transbay',
        'url'     => 'http://www.transbaycalendar.org/',
        'metacat' => 2,
        'id'      => 42
    },
    {
        'url'     => 'http://grayarea.org/events/',
        'label'   => 'grayarea',
        'metacat' => 2,
        'id'      => 43
    },
    {
        'id'      => 44,
        'metacat' => 2,
        'label'   => 'thechapel',
        'url'     => 'http://www.thechapelsf.com/'
    },
    {
        'id'      => 46,
        'metacat' => 2,
        'label'   => 'dna',
        'url'     => 'https://www.dnalounge.com/'
    },
    {
        'url'     => 'http://www.thenewparkway.com/?page_id=13',
        'label'   => 'newparkway',
        'id'      => 2,
        'metacat' => 2
    },
    {
        'label'   => 'funcheap',
        'url'     => 'http://sf.funcheap.com/',
        'metacat' => 2,
        'id'      => 38
    },
    {
        'id'      => 188,
        'metacat' => 2,
        'url'     => 'https://www.indybay.org/',
        'label'   => 'indybay'
    },
    {
        'id'      => 197,
        'metacat' => 2,
        'label'   => 'sfindy',
        'url'     => 'http://sf.indymedia.org/'
    },
    {
        'url'     => 'http://www.spacecowboys.org/',
        'label'   => 'spacecow',
        'metacat' => 2,
        'id'      => 340
    },
    {
        'id'      => 344,
        'metacat' => 2,
        'url'     => 'http://laughingsquid.com/squidlist/events/',
        'label'   => 'squid'
    },
    {
        'metacat' => 2,
        'id'      => 357,
        'label'   => '21grand',
        'url'     => 'http://www.21grand.org/wpress/index.php?s=award'
    },
    {
        'id'      => 361,
        'metacat' => 2,
        'label'   => 'caferoyale',
        'url'     => 'http://www.caferoyale-sf.com/home.shtml'
    },
    {
        'url'     => 'http://thrillpeddlers.com/',
        'label'   => 'thrillped',
        'id'      => 350,
        'metacat' => 2
    },
    {
        'label'   => 'anarchy',
        'url'     => 'http://bayareaanarchistbookfair.com/',
        'metacat' => 2,
        'id'      => 307
    },
    {
        'url'     => 'http://www.sfheart.com/ArtPoetryEvents.html',
        'label'   => 'poets',
        'id'      => 317,
        'metacat' => 2
    }
  ];

   # from in-situ dumps of code (as of May 16, 2019)
   my $cat = bless( {
                      'id'         => 6,
                      'name'       => 'events',
                      'x_location' => 5,
                      'y_location' => 2,
                      'width'      => 130,
                      'height'     => '21.5',
                      'metacat_id'    => 2,
                      'metacat_name'    => 'local',
                      'spots'      => $spots,
                      'cnt'        => '15',
                      'spot_count' => 15,
                      'metacat_sortcode'     => '0020'
                     }, 'Spots::Category' );

   my $placed = [
          bless( {
                   'y_weight' => 1,
                   'coords' => [
                                 5,
                                 0,
                                 123,
                                 '11.1'
                               ],
                   'y1' => 0,
                   'y2' => '11.1',
                   'meta' => {
                               'metacat_name' => 'local',
                               'cat' => 1,
                               'cat_name' => 'oakland',
                               'metacat' => 2
                             },
                   'x1' => 5,
                   'x2' => 123
                 }, 'Spots::Rectangle' ),
          bless( {
                   'meta' => {
                               'metacat_name' => 'local',
                               'cat' => 2,
                               'cat_name' => 'sf',
                               'metacat' => 2
                             },
                   'x1' => 5,
                   'x2' => 123,
                   'y_weight' => 1,
                   'coords' => [
                                 5,
                                 '12.1',
                                 123,
                                 '23.2'
                               ],
                   'y1' => '12.1',
                   'y2' => '23.2'
                 }, 'Spots::Rectangle' ),
          bless( {
                   'meta' => {
                               'metacat_name' => 'local',
                               'cat_name' => 'weather',
                               'cat' => 5,
                               'metacat' => 2
                             },
                   'y_weight' => 1,
                   'coords' => [
                                 5,
                                 '24.2',
                                 183,
                                 '28.8'
                               ]
                 }, 'Spots::Rectangle' )
                ];

  return( $cat, $placed );
}




done_testing();
