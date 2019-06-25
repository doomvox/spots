# Perl test file, can be run like so:
#   perl 50-Spots-HomePage-generate_layout-metacats.t
#          doom@kzsu.stanford.edu     2019/03/27 15:29:51
#                                     2019/06/08

# HISTORY
# A variant of: 03-Spots-HomePage-generate_layout.t
# Intended to test the new 'metacats' layout style
# June 08, 2019: Now modified to test MetacatsFanout.

use 5.10.0;
use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
use Data::Dumper::Names;
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
#  use_ok( 'Spots::HomePage' , )
  use_ok( 'Spots::Test::DB::Init' , );
  use_ok( 'Spots::DB::Handle' , );
  use_ok( 'Spots::HomePage::Layout::MetacatsFanout' , );
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{
   my $subname   = "generate_layout_metacats_fanout";
   my $test_name = "Testing $subname";

   my $tidb = Spots::Test::DB::Init->new();
   my $dbname =
     $tidb->set_up_db_for_test();
   
   my $obj = Spots::HomePage::Layout::MetacatsFanout->new(
                                   dbname => $dbname,
                                  );

   # wipe the coordinate columns in the layout table
   $obj->clear_layout;
   # $obj->generate_layout( $style );
   $obj->generate_layout_metacats_fanout;

   my $dbhh = Spots::DB::Handle->new({ dbname => $dbname });
   my $dbh = $dbhh->dbh;

   my $sql = qq{ select * from layout order by category };
   my $sth = $dbh->prepare( $sql ); 
   $sth->execute();
   my $aref_of_href = $sth->fetchall_arrayref({});
   # say STDERR "aref_of_href: ", Dumper( $aref_of_href );

   is( scalar( @{ $aref_of_href } ), 3 , "$test_name: placed 3 cats" );
   
   my @ids =  sort map{ $_->{id} } @{ $aref_of_href };
   is_deeply( \@ids, [ 1, 2, 3 ], "$test_name: three cat ids, 1, 2, 3");

   my $total_height = sum( map{ $_->{height} } @{ $aref_of_href } );
   say "total_height: $total_height";
   my $expected_height = 9.24 + 9.24 + 3.96;
   cmp_ok( $total_height, '>', ($expected_height - 0.5) );

   # Guessing that the current behavior is okay.
   # Freeze it in place for now--  June 06, 2019:
   my $expected = [
          {
            'id' => 1,
            'category' => 1,
            'width' => 90,
            'height' => '9.24',
            'x_location' => 4,
            'y_location' => 0,
          },
          {
            'id' => 2,
            'category' => 2,
            'width' => 90,
            'height' => '9.24',
            'x_location' => 4,
            'y_location' => 10,
          },
          {
            'id' => 3,
            'category' => 3,
            'width' => 90,
            'height' => '3.96',
            'x_location' => 4,
            'y_location' => 19,
          }
        ];
   is_deeply( $aref_of_href, $expected, "$test_name: placed three cats in a column" );

   # break down
   $dbh->disconnect;
#    my $sidb = $tidb->db_init;
#    $sidb->drop_test_db();
   $tidb->drop_test_db( $dbname );
 }

done_testing();
