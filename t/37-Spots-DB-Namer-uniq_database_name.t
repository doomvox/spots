# Perl test file, can be run like so:
#   perl 37-Spots-DB-Name-uniq_database_name.t
#          doom@kzsu.stanford.edu     2019/05/27 13:37:01

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
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );

use Test::More;

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::DB::Namer' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "uniq_database_name";
   my $test_name = "Testing $subname";

   my $obj    = Spots::DB::Namer->new();
   my $dbname =  $obj->uniq_database_name();

   like( $dbname, qr{ ^ [a-zA-Z0-9_]* $}x, "$test_name: returns a string" );

   my $prefix = $obj->prefix;
   my $suffix = $obj->suffix;

   like( $dbname, qr{ ^ $prefix }x, "$test_name: string has expected prefix" );
   like( $dbname, qr{ $suffix $ }x, "$test_name: string has expected suffix" );
 }

done_testing();
