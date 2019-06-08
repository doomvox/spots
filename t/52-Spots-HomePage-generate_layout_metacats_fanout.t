# Perl test file, can be run like so:
#   perl 52-Spots-HomePage-generate_layout_metacats_fanout.t
#          doom@kzsu.stanford.edu     2019/04/15 05:12:01

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
#  use_ok( 'Spots::HomePage' , );
  use_ok( 'Spots::HomePage::Layout::MetacatsFanout' , );
  use lib ("$Bin/lib/");
  use_ok( 'Spots::Test::DB::Init' , );
  use_ok( 'Spots::DB::Handle' , );
  use_ok( 'Spots::HomePage::Generate', );
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "generate_layout_metacats_fanout";
   my $test_name = "Testing $subname";

   my $tidb = Spots::Test::DB::Init->new();
   my $dbname =
     $tidb->set_up_db_for_test();

   # my $namer =  $tidb->dbnamer;
   my $tp = $tidb->test_prefix;
   my $tNN = 't' . $tp;

   my $out_loc = $tidb->out_loc; # t/out/t22;

   my $expected_html_file = "$out_loc/$tNN.html";
   my $expected_css_file  = "$out_loc/$tNN.css";

   # remove the previously generated files (if any)
   unlink( $expected_html_file ) if -e $expected_html_file;
   unlink( $expected_css_file )  if -e $expected_css_file;

   # Now we should have:
   # 
   #    \c spots_test
   #     select * from category;
   #     id |  name   | metacat 
   #    ----+---------+---------
   #      1 | oakland |       2
   #      2 | sf      |       2
   #      3 | jobs    |      10

   my $expected_cat_count = 3;

   my ($dbh, $sth);

# TODO someday, this old interface might be repaired:
#    my $obj = Spots::HomePage->new(
#                                output_basename  => $tNN,
#                                output_directory => $out_loc,
#                                db_database_name => $dbname,
#                        );

   my $obj = Spots::HomePage::Layout::MetacatsFanout->new(
                               output_basename  => $tNN,
                               output_directory => $out_loc,
                               dbname => $dbname,
                        );



   my $check_cat_skull = qq{ select count(*) as cnt from category };
   $dbh = $obj->dbh;   
   $sth = $dbh->prepare( $check_cat_skull );
   $sth->execute;
   my $cat_check = $sth->fetchall_arrayref({});
   my $cat_count = $cat_check->[0]{ cnt };
   is( $cat_count, $expected_cat_count,
       "Testing that category table has restricted number of rows: $expected_cat_count" );

   # TODO BOOKMARK  the following will need revision for new HomePage.pm
   #                  -- Fri  May 31, 2019  07:40  fandango

   # wipe the coordinate columns in the layout table
   $obj->clear_layout;

   my $style     = 'metacats_fanout';
   $obj->generate_layout( $style );

   my $genner =
     Spots::HomePage::Generate->new(
                               output_basename  => $tNN,
                               output_directory => $out_loc,
                             );

   $genner->html_css_from_layout();

   ok( -e $expected_html_file, "$test_name: html file created" );
   ok( -e $expected_css_file,  "$test_name: css file created" );

   cmp_ok( -s $expected_html_file, '>', 0, "$test_name: html file has contents" );
   cmp_ok( -s $expected_css_file, '>',  0, "$test_name: css file has contents" );

   $dbh = $obj->dbh;
   my $skull = qq{ select * from layout,category where category = category.id order by layout.id };
   $sth = $dbh->prepare( $skull );
   $sth->execute;
   my $layout = $sth->fetchall_arrayref({});

   #  id | category | x_location | y_location | height | width | id |  name   | metacat 
   # ----+----------+------------+------------+--------+-------+----+---------+---------
   #   1 |        1 |          5 |          0 |    8.8 |    83 |  1 | oakland |       2
   #   2 |        2 |          5 |          0 |    8.8 |    83 |  2 | sf      |       2
   #   3 |        3 |          5 |          4 |    4.1 |    83 |  3 | jobs    |      10

   foreach my $lay ( @{ $layout } ) {
     my $x = $lay->{x_location};
     my $y = $lay->{y_location};
     say STDERR "x: $x, y: $y";
   }

   my $check_x = any { $_ > 5 } map{ $_->{ x_location } } @{ $layout };
   ok( not( $check_x ), "$test_name: all x = 5 (for this small set)" );   # TODO BRITTLE?

   my $check_y = any { $_ > 0 } map{ $_->{ y_location } } @{ $layout };
   ok( $check_y, "$test_name: not all y = 0" );


 }



done_testing();
