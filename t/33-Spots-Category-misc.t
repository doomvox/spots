# Perl test file, can be run like so:
#   perl 33-Spots-Category-misc.t
#          doom@kzsu.stanford.edu     Fri  May 24, 2019  20:26  

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
  use_ok( 'Spots::Category'  );
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

{  my $subname = "builder_db_connection";
   my $test_name = "Testing Category class";

   my $obj = Spots::Category->new( { id=>1 } );

   my $cat_hash = $obj->cat_hash;
   is( ref $cat_hash, 'HASH', "Testing cat_hash" );

   my $name = $cat_hash->{name};
   my $expected = 'oakland';  # expected for id=1 as of this writing.
   is( $name, $expected, "Testing internal cat_hash value of name" );

   my $name_via_method = $obj->name;
   is( $name_via_method, $expected, "Testing name via name method" );

   my $expected_mcn = 'local';  # expected for id=1 as of this writing.
   my $metacat_name = $obj->metacat_name;
   is( $metacat_name, $expected_mcn, "Testing name via name method" );

   my $spots = $obj->spots;
   is( ref $spots, 'ARRAY', "Testing spots method return aref." );
   #  say Dumper( $spots );

   my $expected_spot_count = 7; # expected for id=1 as of this writing.
   my $spot_count = $obj->spot_count;
   is( $spot_count, $expected_spot_count, "Testing spot_count method" );

   ok( ( any{ $_->{'url'} eq 'http://actransit.org' } @{ $spots } ),
     "Testing actransit.org url is in the array of spots for oakland" );

   my $height = $obj->height;
   my $y_scale = $obj->y_scale; # 1.3
   # say $height; # 9.1
   # say $height/$y_scale; # 7
   is( $height/$y_scale, $spot_count, "Testing height consistent with spot count and y_scale" );

   my $width  = $obj->width;
   my $x_scale = $obj->x_scale; # 12
   # say $width;  # 108
   # say $width/$x_scale;  # 9
   my $max_chars = 9 ; # max label length of oakland category as of this writing
   is( $width/$x_scale, $max_chars, "Testing width consistent with expected label length and x_scale" );


 }


done_testing();
