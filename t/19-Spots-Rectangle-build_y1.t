# Perl test file, can be run like so:
#   perl 19-Spots-Rectangle-build_y1.t
#          doom@kzsu.stanford.edu     2019/04/12 22:24:54

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
  use_ok( 'Spots::Rectangle' )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "build_y1";
   my $test_name = "Testing $subname";

    
 }

done_testing();
