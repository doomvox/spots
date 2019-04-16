# Perl test file, can be run like so:
#   perl 22-Spots-HomePage-generate_layout_metacats_fanout.t
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
use List::MoreUtils qw( any );

use Test::More;

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::HomePage' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "generate_layout_metacats_fanout";
   my $test_name = "Testing $subname";

   my $output_basename  =  "t22";
   my $output_directory = "$Bin/dat/$output_basename";
   mkpath( $output_directory ) unless -d $output_directory;

   my $expected_html_file = "$output_directory/$output_basename.html";
   my $expected_css_file  = "$output_directory/$output_basename.css";

   # remove the previously generated files (if any)
   unlink( $expected_html_file ) if -e $expected_html_file;
   unlink( $expected_css_file )  if -e $expected_css_file;

   my $db_database_name = 'spots_test'; # vs just 'spots' 

   # trim category table: restrict to a small set of 3 rows
   my $expected_cat_count = 3;
   my $trim_category_skull_file = 
     qq{$Bin/bin/trim_category_table.sql};
   ok( -e $trim_category_skull_file, "Testing db setup sql file needed by test script is available");
   my $setup_db_cmd =<<"___END_SKULL_SET";
     psql -d $db_database_name -f $trim_category_skull_file
___END_SKULL_SET
   system( $setup_db_cmd ) and warn "Problem running $trim_category_skull_file";

   # Now we should have:
   # 
   #    \c spots_test
   #     select * from category;
   #     id |  name   | metacat 
   #    ----+---------+---------
   #      1 | oakland |       2
   #      2 | sf      |       2
   #      3 | jobs    |      10

   my ($dbh, $sth);
   my $obj = Spots::HomePage->new(
                               output_basename  => $output_basename,
                               output_directory => $output_directory,
                               db_database_name => $db_database_name,
                       );

   my $check_cat_skull = qq{ select count(*) as cnt from category };
   $dbh = $obj->dbh;   
   $sth = $dbh->prepare( $check_cat_skull );
   $sth->execute;
   my $cat_check = $sth->fetchall_arrayref({});
   my $cat_count = $cat_check->[0]{ cnt };

   is( $cat_count, $expected_cat_count,
       "Testing that category table has restricted number of rows: $expected_cat_count" );

   # wipe the coordinate columns in the layout table
   $obj->clear_layout;

   my $style     = 'metacats_fanout';
   $obj->generate_layout( $style );

   $obj->html_css_from_layout();

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
   ok( $check_x, "$test_name: not all x = 5" );
   my $check_y = any { $_ > 0 } map{ $_->{ y_location } } @{ $layout };
   ok( $check_y, "$test_name: not all y = 0" );

#    # breakdown: restore data in category table 
#    my $repop_category_skull_file = 
#      qq{$Bin/bin/repop_category_table.sql};
#    ok( -e $trim_category_skull_file, "Testing db setup sql file needed by test script is available");
#    my $repop_db_cmd =<<"___END_SKULL_SET";
#      psql -d $db_database_name -f $trim_category_skull_file
# ___END_SKULL_SET
#    system( $repop_db_cmd ) and warn "Problem running $trim_category_skull_file";

 }

### TODO instead of spots_test, should have a newly created DATABASE with a unique name.

done_testing();
