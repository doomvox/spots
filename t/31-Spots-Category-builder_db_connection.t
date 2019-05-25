# Perl test file, can be run like so:
#   perl 31-Spots-Category-builder_db_connection.t
#          doom@kzsu.stanford.edu     Fri  May 24, 2019  20:26  

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
  use_ok( 'Spots::Category'  );
}

ok(1, "Traditional: If we made it this far, we're ok.");

# $DB::single = 1;

{  my $subname = "builder_db_connection";
   my $test_name = "Testing $subname";

   my $obj = Spots::Category->new( { id=>1 } );
   my $dbh = $obj->builder_db_connection();

   is( ref $dbh, 'DBI::db', "$test_name: returned correct type" );
 }


{  my $subname = "dbh";
   my $test_name = "Testing $subname";

   my $obj = Spots::Category->new( { id=>1 } );
   my $dbh = $obj->dbh;

   is( ref $dbh, 'DBI::db', "$test_name: returned correct type" );

   my $expected = 'hello world';
   my $string = ( $dbh->selectrow_array("select '$expected'") )[0];
   is ($string, $expected, "Testing $subname: using db handle" );
 }

done_testing();
