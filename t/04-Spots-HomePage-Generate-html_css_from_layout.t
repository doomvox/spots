# Perl test file, can be run like so:
#   perl 04-Spots-HomePage-html_css_from_layout.t
#          doom@kzsu.stanford.edu     2019/03/27 18:46:04

# TODO STATUS
# Really needs to use an independent pg database,
# and really needs more extensive test of html/css generation

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
  use_ok( 'Spots::HomePage::Generate', );
  use lib ("$Bin/lib/");
  use_ok( 'Spots::Test::DB::Init' , );
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "html_css_from_layout";
   my $test_name = "Testing $subname";

   my $tidb = Spots::Test::DB::Init->new();
   my $dbname =
     $tidb->set_up_db_for_test();
   my $tp = $tidb->test_prefix;
   my $tNN = 't' . $tp;

   my $output_directory = $tidb->out_loc; # t/out/t04

   mkpath $output_directory unless -d $output_directory;

   my $output_html = "$output_directory/$tNN.html";
   my $output_css  = "$output_directory/$tNN.css";

   unlink($output_html) if -e $output_html;
   unlink($output_css)  if -e $output_css;

   my $obj = Spots::HomePage::Generate->new(
                                   output_basename  => $tNN,
                                   output_directory => $output_directory,
                                   dbname           => $dbname,
#                                   db_database_name => 'spots_test',
#                                   db_database_name => 'spots',
                                  );

   $obj->html_css_from_layout();

   ok( -e $output_html, "$test_name: html file created" );
   ok( -e $output_css,  "$test_name: css file created" );

   my @expected_labels =
     qw(
         oakmus
         oaklib
         oaknet
         actransit
         oakoct
         baycit
         topoak
         sfstreet
         citylab
         sfbike
         bikescape
         bikeebay
         closecall
         telegraph
         perl_jobs
         artmoney
         mojobs
      );

   # check for expected labels *in that order*
   my %labels_found = map { $_ => 0; } @expected_labels;
   open my $fh, '<', $output_html;
   my $label = shift @expected_labels;
   while (my $line = <$fh>) {
     last if not defined $label;
     my $pat = qr{> \s* $label \s* </[aA]>}x;
     if ( $line =~ m{ $pat }x ) {
       $labels_found{ $label } = 1;
       $label = shift @expected_labels;       
     } 
   }

   my $labels_missing = '';
   foreach my $label ( keys %labels_found ) {
     $labels_missing .= " $label " if not( $labels_found{ $label } ) ;
   }

   ok( not( any{ not( $_ ) } values %labels_found ),
       "$test_name: checking if expected labels found and in the right order..." )
     or say $labels_missing;


# TODO 

# Look for lines like this in the css file:

# #cat0001 { position: absolute;                   top:  0rem;                left: 4px;                height: 9.24rem;                       width:  90px;                       margin: 0px;                 padding: 0px;                 border: solid 1px;                 data-catname: oakland; } 
# #cat0002 { position: absolute;                   top:  10rem;                left: 4px;                height: 9.24rem;                       width:  90px;                       margin: 0px;                 padding: 0px;                 border: solid 1px;                 data-catname: sf; } 
# #cat0003 { position: absolute;                   top:  19rem;                left: 4px;                height: 3.96rem;                       width:  90px;                       margin: 0px;                 padding: 0px;                 border: solid 1px;                 data-catname: jobs; } 




 }

done_testing();
