# Perl test file, can be run like so:
#   perl 17-Spots-Rectangle-is_overlapping.t
#          doom@kzsu.stanford.edu     2019/04/07 19:50:57

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

our $test_lib;
BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  our $class = 'Spots::Rectangle';
  use_ok( $class );
  $test_lib = "$Bin/lib/";
}

use lib ($test_lib);
use Spots::Rectangle::TestData qw(:all);  # @is_overlapping_cases

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname   = "is_overlapping";
   my $test_name = "Testing $subname";

  foreach my $case ( @is_overlapping_cases ) { 
     my $r1_coords = $case->{ r1_coords };
     my $r2_coords = $case->{ r2_coords };
     my $expected  = $case->{ expected };
     my $case_name = $case->{ name };

     my $rect1 = Spots::Rectangle->new( coords=>$r1_coords );
     my $rect2 = Spots::Rectangle->new( coords=>$r2_coords );

     my $result = $rect1->is_overlapping( $rect2 );

     my $result_boolean;
     if( $result ) {
       $result_boolean = 1;
     } else {
       $result_boolean = 0;
     }

     my $expected_boolean;
     if( $result ) {
       $expected_boolean = 1;
     } else {
       $expected_boolean = 0;
     }

     is( $result_boolean, $expected_boolean, "$test_name: $case_name" );
   }
 }


done_testing();


