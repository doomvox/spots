# Perl test file, can be run like so:
#   perl 20-Spots-Rectangle-distance.t
#          doom@kzsu.stanford.edu     2019/04/12 22:42:40

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
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::Rectangle' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "distance";
   my $test_name = "Testing $subname";

   my $rect_a = Spots::Rectangle->new({ 
                coords => [ 10, 15, 20, 27 ] 
              });  
   my $rect_b = Spots::Rectangle->new({ 
                coords => [ 35, 55, 50, 70 ] 
              });  
   my $center_to_center_distance = $rect_a->distance( $rect_b, 1 );
   my $check_dist = sprintf( "%.1f", $center_to_center_distance );
   # my $expected_dist = 48.54; # my attempt at manual calculation
   my $expected_dist = 49.8; # freezing behavior   TODO 
   is( $check_dist, $expected_dist, "$test_name" );
 }

done_testing();
