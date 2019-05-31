# Perl test file, can be run like so:
#   perl 14-Spots-HomePage-generate_layout_for_row.t
#          doom@kzsu.stanford.edu     2019/03/31 07:20:15

use 5.10.0;
use warnings;
use strict;
$|=1;
my $DEBUG = 1;              # TODO set to 0 before ship
# use Data::Dumper;
use Data::Dumper::Perltidy;
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

# $DB::single = 1;
# Insert your test code below.  Consult perldoc Test::More for help.

{ 
   my $test_name = "Testing new";
   my $class = 'Spots::HomePage';   

   my $args_mess = 'without arguments';
   my $obj = Spots::HomePage->new();
   is( ref $obj, $class, "Testing $class->new with $args_mess" );
 }

{  my $subname = "generate_layout_for_row";
   my $style   = "metacats_doublezig";
   my $test_name = "Testing $subname with $style";

   my $base = "t14";
#   my $output_directory = "$Bin/dat/$base";
   my $output_directory = "$Bin/src/$base";

   my $obj = Spots::HomePage->new(
                                  output_basename  => $base,
                                  output_directory => $output_directory,
                                  db_database_name => 'spots_test',
                                  );
   { no warnings 'once';
    $DB::single = 1;
    # b Spots::HomePage::generate_layout_for_row
    }

   my $class = 'Spots::HomePage';   

   my $args_mess = 'args: db_database_name, output_basenmae, output_directory';
   is( ref $obj, $class, "Testing $class->new with $args_mess" );

   # This $cats subs for category table, but code uses data from
   # spots table in DATABASE spots_test
   my $cats =
     [ {
        'id'   => 7,
        'cnt'  => 23,
        'name' => 'news'
       },
       {
        'name' => 'perl',
        'id'   => 16,
        'cnt'  => 23
       },
       {
        'cnt'  => 20,
        'id'   => 23,
        'name' => 'otaku'
       }];

   my $initial_x = 5;
   my $initial_y = 0;

    my ( $row_layout, $max_h ) =
      $obj->generate_layout_for_row( $cats, $initial_x, $initial_y );

   print STDERR "row_layout: ". Dumper( $row_layout ), "max_h: $max_h"; 
   my $expected_row_layout =
   #     id    x        y       h     w
     [ [  7,   5,       0,      92,  '27.5' ],
       [ 16, 101,       0,     101,  '27.5' ],
       [ 23, 206,       0,     146,  '24.0' ]
     ];

   is_deeply( $row_layout, $expected_row_layout, "$test_name: row_layout" );

   my $expected_max_h = 27.5; 
   is( $max_h, $expected_max_h, "$test_name: max_h" );
}

done_testing();
