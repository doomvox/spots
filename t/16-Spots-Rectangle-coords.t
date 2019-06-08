# Perl test file, can be run like so:
#   perl 16-Spots-Rectangle-coords.t
#          doom@kzsu.stanford.edu     2019/04/07 16:32:05

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
  use_ok( 'Spots::Rectangle' , );
  use_ok( 'Spots::Rectangle::TestData', ':all' );
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "coords";
   my $class_exp = "Spots::Rectangle";
   my $test_name = "Testing $subname";

   my $x1_exp = 3;
   my $y1_exp = 13;
   my $x2_exp = 6;
   my $y2_exp = 16;

   my $coords_exp = [ $x1_exp, $y1_exp, $x2_exp, $y2_exp ];
   my $obj = $class_exp->new( coords => $coords_exp );

   my $x1 = $obj->x1;
   is( $x1, $x1_exp, "$test_name: x1 accessor" );
   
   my $y1 = $obj->y1;
   is( $y1, $y1_exp, "$test_name: y1 accessor" );

   my $coords = $obj->coords();
   is_deeply( $coords, $coords_exp, "$test_name: coords accessor" );

 }

done_testing();
