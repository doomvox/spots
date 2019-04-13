# Perl test file, can be run like so:
#   perl 19-Spots-Rectangle-calculate_center.t
#          doom@kzsu.stanford.edu     2019/04/12 22:25:26

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

{  my $subname = "calculate_center";
   my $test_name = "Testing $subname";

   my $r1_coords = [ 10, 15, 20, 27 ];

   my $rect = Spots::Rectangle->new( coords=>$r1_coords );
   my ($xc, $yc) = @{ $rect->calculate_center() };

#              10           xc          20
#               .            .           .
#    o-------------------------------------->  x
#    |                        
#    |                        
#    |       (10, 15)         
#    |                        
#    |- 15      o------------------------o
#    |          |                        |
#    |          |                        |     
#    |          |                        |     
#    |- yc      |            x           |     
#    |          |                        |     
#    |          |                        |     
#    |          |                        |     
#    |- 27      o------------------------o     
#    |                                         
#    V                                 (20, 27)
#                           
#    y                        
#                           
#           xc = (20 - 10)/2  + 10  = 15
#           yc = (27 - 15)/2  + 15  = 21
# 


   is( $xc, 15, "$test_name: x of center" );
   is( $yc, 21, "$test_name: y of center" );

 }

{  my $subname = "center";
   my $test_name = "Testing $subname";

   my $r1_coords = [ 10, 15, 20, 27 ];

   my $rect = Spots::Rectangle->new( coords=>$r1_coords );
   my ($xc, $yc) = @{ $rect->center() };
   is( $xc, 15, "$test_name: x of center" );
   is( $yc, 21, "$test_name: y of center" );
 }




done_testing();
