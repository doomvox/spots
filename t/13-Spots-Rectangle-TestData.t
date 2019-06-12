# Perl test file, can be run like so:
#   perl 13-Spots-Rectangle-TestData.t
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
  use lib ("$Bin/lib");
  use_ok( 'Spots::Rectangle::TestData', ':all' );
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{ 
  my $test_name = "Testing placed data structures";
  my $placed_grendel1 = generate_placed_grendel1();
  my $placed_grendel1_raw = generate_placed_raw();
  
  is_deeply( $placed_grendel1, $placed_grendel1_raw,
             "$test_name: refactored form matches raw form" );
}

done_testing();
