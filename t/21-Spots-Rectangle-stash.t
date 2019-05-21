# Perl test file, can be run like so:
#   perl 21-Spots-Rectangle-stash.t
#          doom@kzsu.stanford.edu     2019/04/13 21:22:18

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

{  my $subname = "stash";
   my $test_name = "Testing $subname";

   my ($x1, $y1, $x2, $y2) = ( 4, 13, 16, 27 );
   my $rect = Spots::Rectangle->new( coords => [ $x1, $y1, $x2, $y2 ] );

   my $key   = 'ster';
   my $value = 'bupkes';

   $rect->stash( $key, $value );

   my $meta = $rect->meta;
   
   my $expected_meta = { ster => $value };
   is_deeply( $meta, $expected_meta, "$test_name: stashed value is in meta  " ); 

   my $retrieved = $rect->unstash( $key );

   is( $retrieved, $value, "$test_name: retrieved value via hsats checks" );
 }


{  my $subname = "metacat";
   my $test_name = "Testing $subname";

   my ($x1, $y1, $x2, $y2) = ( 4, 13, 16, 27 );
   my $rect = Spots::Rectangle->new( coords => [ $x1, $y1, $x2, $y2 ] );

   my $key   = 'metacat';
   my $value = 66;

   $rect->stash( $key, $value );

   my $meta = $rect->meta;

   my $expected_meta = { metacat => $value };
   is_deeply( $meta, $expected_meta, "$test_name: stashed value is in meta  " ); 

   my $retrieved = $rect->metacat;

   is( $retrieved, $value, "$test_name: retrieved value via metacat checks" );
 }


done_testing();
