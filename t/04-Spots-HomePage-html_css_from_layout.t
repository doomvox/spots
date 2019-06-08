# Perl test file, can be run like so:
#   perl 04-Spots-HomePage-html_css_from_layout.t
#          doom@kzsu.stanford.edu     2019/03/27 18:46:04

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
# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "html_css_from_layout";
   my $test_name = "Testing $subname";

   my $base = "t04";
#   my $output_directory = "$Bin/dat/$base";
   my $output_directory = "$Bin/src/$base";

   mkpath $output_directory unless -d $output_directory;

   my $output_html = "$output_directory/$base.html";
   my $output_css = "$output_directory/$base.css";

   unlink($output_html) if -e $output_html;
   unlink($output_css)  if -e $output_css;

#    say STDERR "*.t uses output_html: $output_html";
#    say STDERR "*.t uses output_css: $output_css";

   my $obj = Spots::HomePage->new(
                                   output_basename  => $base,
                                   output_directory => $output_directory,
                                   db_database_name => 'spots_test',
#                                   db_database_name => 'spots',
                                  );

   $obj->html_css_from_layout();

   ok( -e $output_html, "$test_name: html file created" );
   ok( -e $output_css,  "$test_name: css file created" );

#  TODO 

#    # check coordinate cols: loaded with expected data?
#    my $cat_id = 33;
#    my ($cat_spots, $spot_count, $x, $y, $w, $h) = 
#      $obj->lookup_cat_and_size( $cat_id );  

# #    say STDERR "cat_spots: ", Dumper($cat_spots), "\n";
# #    say STDERR "spot_count: $spot_count, x: $x, y: $y, w: $w, h: $h";

#    # spot_count: 11, x: 5, y: 46, w: 108, h: 13
#    my $cnt_33 = 11;
#    is( $spot_count, $cnt_33, "$test_name: count of spots in $cat_id is $cnt_33" );
#    is( $x, 5,  "$test_name: x coord of $cat_id" );
#    is( $y, 46, "$test_name: y coord of $cat_id" );

#    is( $w, 108, "$test_name: width of $cat_id" );
#    is( $h,  13, "$test_name: height of $cat_id" );

#    my $label = 'bale';
#    my $detected_label = any{ $_->{ label } eq $label } @{ $cat_spots };
#    ok( $detected_label, "$test_name: cat id $cat_id includes label $label" );


# Look for something like this in the html file:

# <div class="category" id="cat0033" data-catname="linux" >
# <a href="http://debaday.debian.net/">debaday</a><br>
# <a href="http://kernelnewbies.org/">kern_newbs</a><br>
# <a href="http://www.debian-administration.org/">debadmin</a><br>
# <a href="http://linuxtoday.com/">today</a><br>
# <a href="http://www.oreillynet.com/">oreilly_i_do</a><br>
# <a href="http://www.linuxnews.com/">news</a><br>
# <a href="http://linuxmafia.com/">mafia</a><br>
# <a href="http://linuxhomepage.com/">hpage</a><br>
# <a href="http://www.phoronix.com/scan.php?page=home">phoronix</a><br>
# <a href="http://linuxmafia.com/bale/">bale</a><br>
# <a href="http://www.twit.tv/FLOSS">floss</a><br>
# </div>

# Look for this line in the css file:

#  #cat0033 { position: absolute;                   top:  46rem;                left: 5px;                height: 13rem;                       width:  108px;                       data-catname: linux; } 





 }

done_testing();
