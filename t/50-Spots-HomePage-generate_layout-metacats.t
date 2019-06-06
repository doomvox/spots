# Perl test file, can be run like so:
#   perl 50-Spots-HomePage-generate_layout-metacats.t
#          doom@kzsu.stanford.edu     2019/03/27 15:29:51

# Variant of: 03-Spots-HomePage-generate_layout.t
#             to test the new 'metacats' layout style

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

   # Guessing that the current behavior is okay.
   # Freeze it in place for now--  June 01, 2019
#    my $expected = [
#           {
#             'id'         => 3,
#             'y_location' => 20,
#             'height'     => '9.1',
#             'width'      => 108,
#             'x_location' => 5,
#             'category'   => 1,
#           },
#           {
#             'id'         => 1,
#             'y_location' => 0,
#             'height'     => '9.1',
#             'width'      => 108,
#             'x_location' => 5,
#             'category'   => 2,
#           },
#           {
#             'id'         => 2,
#             'y_location' => 10,
#             'height'     => '3.9',
#             'width'      => 108,
#             'x_location' => 5,
#             'category'   => 3,
#           }
#         ];

# And again, Wed  June 05, 2019  00:50  fandango
   my $expected = [
          {
            'x_location' => 5,
            'width' => 108,
            'id' => 3,
            'category' => 1,
            'height' => '11.2',
            'y_location' => 22
          },
          {
            'y_location' => 0,
            'category' => 2,
            'height' => '11.2',
            'id' => 1,
            'width' => 108,
            'x_location' => 5
          },
          {
            'x_location' => 5,
            'width' => 108,
            'id' => 2,
            'category' => 3,
            'height' => '4.8',
            'y_location' => 12
          }
        ];


   is_deeply( $aref_of_href, $expected, "$test_name: placed three cats in a column" );

#    # break down
#    $dbh->disconnect;
#    my $sidb = $tidb->db_init;
#    $sidb->drop_db();
 }

done_testing();
