# Perl test file, can be run like so:
#   perl 40-Spots-DB-Init.t
#          doom@kzsu.stanford.edu     2019/05/27 20:36:30

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

my $SRC_LOC;
BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::DB::Init' , );
  use_ok( 'Spots::DB::Init::Namer' , );
  use_ok( 'Spots::DB::Handle' , );
#  $SRC_LOC = "$Bin/dat/t40";
  $SRC_LOC = "$Bin/src/t40";
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "";
   my $test_name = "Testing $subname";

   my $dbnamer = Spots::DB::Init::Namer->new();
   my $dbname = $dbnamer->uniq_database_name();  
   say "dbname: $dbname"; # dbname: spots_fandango_27171_20423_test
   my $prefix = $dbnamer->prefix;
   my $suffix = $dbnamer->suffix;

   my $src_loc = "$SRC_LOC/src";
   my $out_loc = "$SRC_LOC/out";
   mkpath( $src_loc ) unless -d $src_loc;
   mkpath( $out_loc ) unless -d $out_loc;

   my $date_stamp = $dbnamer->yyyy_month_dd;

   # /home/doom/End/Cave/Spots/Wall/Spots/t/dat/t40/src/spots_schema.sql
   my $db_schema_file        = $src_loc . '/' . $prefix . "schema.sql";
   # /home/doom/End/Cave/Spots/Wall/Spots/t/dat/t40/src/spots_data.sql
   my $db_data_file       = $src_loc . '/' . $prefix . "data.sql"; 

   my $schema_backup_file = $out_loc . '/' . $prefix . "schema" . '_' . "$date_stamp.sql";
   my $data_backup_file   = $out_loc . '/' . $prefix . "data"   . '_' . "$date_stamp.sql";
   my $pg_restore_file    = $out_loc . '/' . $prefix . "$date_stamp.pg_restore";
   my $log_file           = $out_loc . '/' . $prefix . "$date_stamp.log";

   my $sidb =
     Spots::DB::Init->new({        dbname             => $dbname,
                                   live               => 0,  # Note: flipping it on below.
                                   verbose            => 1,
                                   debug              => 1,
                                   unsafe             => 0,
                                   log_loc            => "$out_loc",
                                   backup_loc         => "$out_loc",
                                   schema_loc         => "$src_loc", 
                                   data_loc           => "$src_loc", 
                                   
                                   schema_backup_file => "$schema_backup_file", 
                                   data_backup_file   => "$data_backup_file", 
                                   pg_restore_file    => "$pg_restore_file", 
                                   log_file           => "$log_file", 
                                   db_schema_file     => "$db_schema_file", 
                                   db_data_file       => "$db_data_file", 

                                 });

   $sidb->live( 1 );

   $test_name = "Testing $subname: create_db";
   my $existing_databases = $dbnamer->list_databases;
   $sidb->create_db;
   my $all_databases = $dbnamer->list_databases;
   my $found = any{ $dbname eq $_ } @{ $all_databases };
   ok( ($found),  "$test_name: found newly created db $dbname" );

   $test_name = "Testing $subname: load_schema";
   $sidb->load_schema;

   my $dbhh = Spots::DB::Handle->new( dbname => $dbname, );
   my $dbh = $dbhh->dbh;

   my $sql = qq{select name from category};
   my $before = $dbh->selectall_arrayref($sql);

   # say "before: ", Dumper( $before );
   is( scalar( @{ $before } ), 0, "$test_name: table category exists, but has no rows" );

   $test_name = "Testing $subname: load_data";
   $sidb->load_data;

   $dbh->disconnect; # switching to another db handle to be neat (probably no need)
   my $dbhh2 = Spots::DB::Handle->new( dbname => $dbname, );
   my $dbh2 = $dbhh2->dbh;

   my $after = $dbh2->selectall_arrayref($sql);
   # say "after: ", Dumper( $after );
   is( scalar( @{ $after } ), 3, "$test_name: table category has three rows" );

   my @category_names = map{ $_->[0]  } @{ $after };
   say Dumper( \@category_names );

   my @expected = ( 'oakland', 'sf', 'jobs' );

   is_deeply( \@category_names, \@expected, "$test_name: three expected category names");
   $dbh2->disconnect;  # Needed or else drop_db will fail: "other users" connected to dbname

   # breakdown
   $test_name = "Testing drop_db";
   $sidb->verbose( 1 );
   $sidb->drop_db(); # unless in unsafe mode, refuses to work if not named *_test
   $all_databases = $dbnamer->list_databases;
   $found = any{ $dbname eq $_ } @{ $all_databases };
   ok( not($found),  "$test_name: dropped db $dbname" );

 }

done_testing();
