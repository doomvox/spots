# Perl test file, can be run like so:
#   perl 02-Spots-HomePage.t
#          doom@kzsu.stanford.edu     2019/03/26 16:16:22

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

# $DB::single = 1;

{  my $subname = "accessors";
   my $test_name = "Testing $subname";

   my $obj = Spots::HomePage->new();

   # has db_database_name => (is => 'rw', isa => Str, default => 'spots' );

   my $dbname = $obj->db_database_name;
   is( $dbname, 'spots', "$test_name: db_database_name" );

   $obj->db_database_name('spots_test');
   $dbname = $obj->db_database_name;
   is( $dbname, 'spots_test', "$test_name: db_database_name changed" );

   my $outdir = $obj->output_directory;
   is( $outdir,  '/home/doom/End/Cave/Spots/Wall', "$test_name: output_directory" );

   $obj->output_directory('/home/doom/End/Cave/Spots/tmp');
   $outdir = $obj->output_directory;
   is( $outdir,  '/home/doom/End/Cave/Spots/tmp', "$test_name: output_directory changed" );

 }

{  my $subname = "argument to new";
   my $test_name = "Testing $subname";

   my $obj = Spots::HomePage->new(
                                  db_database_name => 'spots_test',
                                  output_directory => '/home/doom/tmp',
                                 );

   my $dbname = $obj->db_database_name;
   is( $dbname, 'spots_test', "$test_name: db_database_name" );

   my $outdir = $obj->output_directory;
   is( $outdir,  '/home/doom/tmp', "$test_name: output_directory" );
 }

# {  my $subname = "html_fh";
#    my $test_name = "Testing $subname";

#    my $pwd = cwd();
#    my $output_directory = "$pwd/dat/t02";
#    mkpath( $output_directory ) unless -d $output_directory;

#    my $base = "02-$subname";

#    $DB::single = 1;
#    my $obj = Spots::HomePage->new(
#                                   db_database_name => 'spots_test',
#                                   output_basename  => $base,
#                                   output_directory => $output_directory,
#                                  );

#    my $html_file = $obj->html_file;
#    like($html_file, qr/$base/ , "html_file contains expected basename: $base");

#    my $fh = $obj->html_fh;

#    my $link_line = qq{<A HREF="http://obsidianrook.com/doomfiles/TOP.html">TOP</A>\n};
#    print {$fh}  $link_line;
#    print {$fh}  $link_line;
#    print {$fh}  $link_line;
#    close( $fh );

#    my $file = "$output_directory/$base.html";

#    ok( -e $file, "$test_name: created file $file" );

#    open( my $fhout, '<', $file );
#    undef $/;
#    my @lines = <$fhout>;
#    print STDERR Dumper( \@lines ), "\n";

#    my $l = scalar( @lines );
#    is( $l, 3, "$test_name: count of lines written to file is correct: 3");

#    like($lines[0], qr/TOP/ , "first line read back from html_file contains expected string: TOP");   
#  }



done_testing();
