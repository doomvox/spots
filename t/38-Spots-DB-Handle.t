# Perl test file, can be run like so:
#   perl 38-Spots-DB-Handle.t
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
  use_ok( 'Spots::DB::Handle' , );
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "new";
   my $test_name = "Testing $subname";

   my $obj    = Spots::DB::Handle->new();
   is( ref $obj, 'Spots::DB::Handle', "$test_name" );

   $test_name = "Testing dbh accessor";
   my $dbh = $obj->dbh;
   is( ref $dbh, 'DBI::db', "$test_name: right class for a db handle" );

   ok( ($dbh->ping), "Testing: using dbh ping" );

   my $sql = "select 'low' AS hell";
   my $expected = { 'hell' => 'low' };
   my $href = $dbh->selectrow_hashref($sql);
   # say Dumper( $href );
   is_deeply( $href, $expected, "$test_name: simple select" );
 }

done_testing();
