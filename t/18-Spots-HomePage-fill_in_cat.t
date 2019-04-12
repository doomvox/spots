# Perl test file, can be run like so:
#   perl 18-Spots-HomePage-fill_in_cat.t
#          doom@kzsu.stanford.edu     2019/04/11 00:34:12

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
  use_ok( 'Spots::HomePage' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "fill_in_cat";
   my $test_name = "Testing $subname";

   my $obj = Spots::HomePage->new();

   my $cats =  $obj->list_all_cats(); 

   my $cat = $cats->[0];

   $obj->fill_in_cat( $cat );

#    say Dumper( $cat );

   my $height = $cat->{ height };
   my $width = $cat->{ width };

   my ($height_expected, $width_expected ) =  (9, 83);
   is ($height, $height_expected, "$test_name: height" );
   is ($width, $width_expected, "$test_name: width" );

   my $spot_count = $cat->{ spot_count };
   my $expected_spot_count = 7;
   is( $spot_count, $expected_spot_count, "$test_name: spot_count" );
   
 }

done_testing();
