# Perl test file, can be run like so:
#   perl 23-Spots-Rectangle-edge_distance.t
#          doom@kzsu.stanford.edu     2019/05/09 21:35:26

use 5.10.0;
use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use Fatal           qw( open close mkpath copy move );
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::MoreUtils qw( any );

use Test::More;

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");  # /home/doom/End/Cave/Spots/Wall/Spots/lib
  use lib ("$Bin/lib/");     # /home/doom/End/Cave/Spots/Wall/Spots/t/lib
  use_ok( 'Spots::Rectangle' , );
  use_ok( 'Spots::Rectangle::TestData', ':all' );   # @edge_distance_cases, draw_cases
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

#my $pic_loc = "$Bin/dat/t23";
my $pic_loc = "$Bin/src/t23";
mkpath( $pic_loc ) unless -d $pic_loc;

{  my $subname   = "edge_distance";
   my $test_name = "Testing $subname";

   foreach my $case ( @edge_distance_cases  ) { 
     my $r1_coords = $case->{ r1_coords };
     my $r2_coords = $case->{ r2_coords };
     my $expected  = $case->{ expected };
     my $case_name = $case->{ name };

     my $rect_a = Spots::Rectangle->new( coords=>$r1_coords );
     my $rect_b = Spots::Rectangle->new( coords=>$r2_coords );

     my $edge_distance = $rect_a->edge_distance( $rect_b, 1 );
     my $check_dist = sprintf( "%.1f", $edge_distance ) + 0;
     is( $check_dist, $expected, "$test_name: $case_name" );
   }

   draw_cases( \@edge_distance_cases, $pic_loc, 'rect_pairs' )
}

done_testing();
