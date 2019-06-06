# Perl test file, can be run like so:
#   perl 13-Spots-HomePage-generate_layout-metacats.t
#          doom@kzsu.stanford.edu     2019/03/27 15:29:51

# Variant of: 03-Spots-HomePage-generate_layout.t
#             to test the new 'metacats' layout style

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

{ no warnings 'once';
  $DB::single = 1;
}
# b Spots::HomePage::generate_layout

{  my $subname = "generate_layout";
   my $style   = "metacats_doublezig";
   my $test_name = "Testing $subname with $style";

   my $base = "t03";
#   my $output_directory = "$Bin/dat/$base";
   my $output_directory = "$Bin/src/$base";

   my $obj = Spots::HomePage->new(
                                   output_basename  => $base,
                                   output_directory => $output_directory,
                                   db_database_name => 'spots_test',
#                                   db_database_name => 'spots',
                                  );

   # wipe the coordinate columns in the layout table
   $obj->clear_layout;

   $obj->generate_layout( $style );

   # check coordinate cols: loaded with expected data?
   my $cat_id = 33;
   my ($cat_spots, $spot_count, $x, $y, $w, $h) = 
     $obj->lookup_cat_and_size( $cat_id );  

#    say STDERR "cat_spots: ", Dumper($cat_spots), "\n";
#    say STDERR "spot_count: $spot_count, x: $x, y: $y, w: $w, h: $h";

   # spot_count: 11, x: 5, y: 46, w: 108, h: 13
   my $cnt_33 = 11;
   is( $spot_count, $cnt_33, "$test_name: count of spots in $cat_id is $cnt_33" );

## TODO verify that these numbers seem sensible (just freezing results)
   # is( $x, 521,  "$test_name: x coord of $cat_id" );  
   is( $x, 293,  "$test_name: x coord of $cat_id" );  
   # is( $y, 29, "$test_name: y coord of $cat_id" );
   is( $y, 28, "$test_name: y coord of $cat_id" );
   is( $w, 110, "$test_name: width of $cat_id" );
   is( $h,  13.5, "$test_name: height of $cat_id" );

   my $label = 'bale';
   my $detected_label = any{ $_->{ label } eq $label } @{ $cat_spots };
   ok( $detected_label, "$test_name: cat id $cat_id includes label $label" );
 }

done_testing();