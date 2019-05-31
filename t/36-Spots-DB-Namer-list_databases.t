# Perl test file, can be run like so:
#   perl 36-Spots-DB-Name-list_databases.t
#          doom@kzsu.stanford.edu     2019/05/27 13:17:01

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
use Env             qw( HOME USER );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );

use Test::More;

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::DB::Init::Namer' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "list_databases";
   my $test_name = "Testing $subname";

   my $obj = Spots::DB::Init::Namer->new();
   my $dbs = $obj->list_databases();
   # say Dumper( $dbs );

   my @expected = ( 'template0', 'template0', 'postgres', $USER ); 
   foreach my $expected ( @expected ) {
     ok( (any{ $_ eq $expected } @{ $dbs } ),
       "$test_name: found $expected ");
   }

 }

done_testing();
