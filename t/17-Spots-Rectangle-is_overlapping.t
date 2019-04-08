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

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::Rectangle' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "is_overlapping";
   my $test_name = "Testing $subname";

   my $r1_coords = [ 10, 10, 20, 20 ];

   my $rect1 = Spots::Rectangle->new( coords=>$r1_coords );

   my @cases = (
                { r2_coords => [ 20, 20, 25, 15 ],
                  expected  => 0, # false, no-overlap
                  name => "no-overlap: second is diagonally adjacent from first",
                  },
                { r2_coords => [ 5, 12, 12, 18 ],
                  expected  => 1, # true, overlap
                  name => "overlap: second pushes through left side of first",
                },
                { r2_coords => [ 19, 15, 30, 25 ],
                  expected  => 1, # true, overlap
                  name => "overlap: second has upper-left corner over lower-right of first",
                  },
                { r2_coords => [ 12, 18, 15, 30 ],
                  expected  => 1, # true, overlap
                  name => "overlap: second pushes through bottom of the first",
                  },
                { r2_coords => [ 10, 30, 20, 40 ],
                  expected  => 0, # false, no-overlap
                  name => "no-overlap: second is below the first",
                  },
                { r2_coords => [ 25, 10, 45, 20 ],
                  expected  => 0, # false, no-overlap
                  name => "no-overlap: second is to the right of 1st",
                  },
                { r2_coords => [ 10, 20, 20, 40 ],
                  expected  => 1, # true, overlap
                  name => "overlap: top edge coincident, 2nd below 1st",
                  },

                { r2_coords => [ 20, 20, 30, 30 ],
                  expected  => 1, # true, overlap
                  name => "overlap: upper-right corner same as lower-left of 1st",
                  },
                { r2_coords => [ 11, 11, 19, 19 ],
                  expected  => 1, # true, overlap
                  name => "totally overlapped: second is inside of the first",
                  },

                { r2_coords => [ 8, 8, 22, 22 ],
                  expected  => 1, # true, overlap
                  name => "totally overlapped: second is outside of the first",
                  },

                { r2_coords => [ 10, 10, 20, 20 ],
                  expected  => 1, # true, overlap
                  name => "totally overlapped: second is same as the first",
                  },
              );

   foreach my $case ( @cases ) { 
     my $r2_coords = $case->{ r2_coords };
     my $expected  = $case->{ expected };
     my $case_name = $case->{ name };

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
