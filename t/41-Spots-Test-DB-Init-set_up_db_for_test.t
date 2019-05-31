# Perl test file, can be run like so:
#   perl 41-Spots-Test-DB-Init-set_up_db_for_test.t
#          doom@kzsu.stanford.edu     2019/05/29 22:54:54

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
  use lib ("$Bin/lib/");
  use_ok( 'Spots::Test::DB::Init' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "builder_db_init";
   my $test_name = "Testing $subname";

   my $obj = Spots::Test::DB::Init->new();
   my $dbname =
     $obj->set_up_db_for_test();

   say $dbname;
   say STDERR "dbname: ", Dumper( $dbname );

 }

done_testing();
