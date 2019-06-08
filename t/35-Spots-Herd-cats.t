# Perl test file, can be run like so:
#   perl 35-Spots-Herd-cats.t
#          doom@kzsu.stanford.edu     May 24,  2019

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
use Env             qw( HOME );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );

use Test::More;

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Spots::Herd' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }

# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "cat_ids";
   my $test_name = "Testing $subname";

   my $obj = Spots::Herd->new();
   my $all_cat_ids = $obj->cat_ids;

#   say Dumper( $all_cat_ids );
#    $VAR1 = [
#           43,
#           1,
#           2,

   cmp_ok( scalar( @{ $all_cat_ids } ), '>', 40, "$test_name: plausible number of cats" );

   my $cat_25 = $all_cat_ids->[ 25 ];
   like( $cat_25, qr{^[0-9]+$}, "$test_name: spot check id 25 looks numeric");

   my $cat_10 = $all_cat_ids->[ 10 ];
   like( $cat_10, qr{^[0-9]+$}, "$test_name: spot check id 10 looks numeric");
 }

{ my $subname = 'cats';
  my $test_name = "Testing $subname accessor";

  my $obj = Spots::Herd->new();
  my $cats = $obj->cats;
  # say "cats: " . Dumper( $cats ); # DEBUG
  
  is( ref $cats, 'ARRAY', "$test_name: returns an aref" );

  my $first = $cats->[0];
  is( ref $first, 'Spots::Category', "$test_name: elements look like Spots::Category objects." );

  # my @fields = sort keys %{ $first };  # limited: lazy=>1
  # say Dumper( \@fields );
  #   $VAR1 = [
  #           'db_dbname',
  #           'debug',
  #           'id',
  #           'x_scale',
  #           'y_scale'
  #         ];

  {
    # select cat with id 36
    my $cat = ( grep{ $_->id == 36 } @{ $cats } )[0];
    my $id     = $cat->id;       # 36
    my $height = sprintf "%.1f", $cat->height;   # 1.3 (ok)
    my $width  = $cat->width;    # 60
    my $name   = $cat->name;     # 'politics'
    # say "~~> name: $name  height: $height  width: $width  name: $name";  #DEBUG
    is( $id, 36, "$test_name: found cat of id 36" );
    is( $name, 'politics', "$test_name: a cat named 'politics'" );
    cmp_ok( $height, '>=', 0.5, "$test_name: height over 0.5");
    cmp_ok( $height, '<=', 5.0, "$test_name: height under 5.0");

    cmp_ok( $width, '>=', 40, "$test_name: width over 40");
    cmp_ok( $width, '<=', 80, "$test_name: width under 80");
  }

  {
    # select cat id 57 checking for name 'sanfrancisco'
    my $exp_name = 'san_francisco';
    my $cat = first{ $_->name eq $exp_name } @{ $cats }; # uniq better than first

    my $id     = $cat->id;      # 57
    my $height = sprintf "%.1f", $cat->height;  # 3.9 (ok)
    my $width  = $cat->width;   # 132 (?)
    my $name   = $cat->name;    # 'san_francisco'
    # say "~~> name: $name  height: $height  width: $width  name: $name"; # DEBUG

    is( $id, 57, "$test_name: found cat of id 57" );
    is( $name, $exp_name, "$test_name: a cat named '$exp_name'" );
    cmp_ok( $height, '>=', 2, "$test_name: height over 2");
    cmp_ok( $height, '<=', 5, "$test_name: height under 5");

    cmp_ok( $width, '>=', 100, "$test_name: width over 100");
    cmp_ok( $width, '<=', 150, "$test_name: width under 150");

#     my @labels = map{ $_->name } @{ $cats };
#     foreach my $l ( @labels ) {
#       printf "%4d: %s\n", length($l), $l;
#     }

    my $length_raw =
      max map{ length($_->name) } grep{ $_->name eq $exp_name } @{ $cats }; # 13
    # estimating likely range of label field width
    my ($l_low, $l_high) = (4, 30);
    cmp_ok( $length_raw, '>=', $l_low,  "$test_name: max label length $length_raw > than likely low: $l_low");
    cmp_ok( $length_raw, '<=', $l_high, "$test_name: max label length $length_raw < than likely high: $l_high");

    # estimating likely range of scaling factor
    my ($scale_low, $scale_high) = (6, 15);
    my ($low, $high) = ($length_raw * $scale_low, $length_raw * $scale_high);
    cmp_ok( $width, '>=', $low,  "$test_name: width $width > than likely low: $low");    # 22
    cmp_ok( $width, '<=', $high, "$test_name:  width $width < than likely high: $high");

    my $spot_count = $cat->spot_count;
    # estimating likely range of spot_count for a category
    my ($sc_low, $sc_high) = (1, 100);
    cmp_ok( $spot_count, '>=', $sc_low,  "$test_name:  spot_count $spot_count > $sc_low");
    cmp_ok( $spot_count, '<=', $sc_high, "$test_name:  spot_count $spot_count < $sc_high");

    # estimating likely range of scaling factor
    my ($y_scale_low, $y_scale_high) = (1, 1.5);  # currently 1.32
    my ($y_low, $y_high) = ($spot_count * $y_scale_low, $spot_count * $y_scale_high);
    cmp_ok( $height, '>=', $y_low,  "$test_name:  height $height > than likely low: $y_low");
    cmp_ok( $height, '<=', $y_high, "$test_name:  height $height < than likely high: $y_high");
  }

  {
    # select cat with id 57, or name 'sanfrancisco'
    my $name = 'san_francisco';
#    my $cat = ( grep{ $_->id == 57 } @{ $cats } )[0];
#    say $cat->name;

    #  my $cat = ( grep{ $_->name eq $name } @{ $cats } )[0];
    my $cat = first{ $_->name eq $name } @{ $cats };

    my $spots = $cat->spots;
    my $spot_count = $cat->spot_count;
    is( scalar( @{ $spots } ), $spot_count, "$test_name: spot_count matches returned spots" );

    my @labels = sort map{ $_->{label} } @{ $spots };
    my @expected_labels = qw( kinokiniya noisebridge sfpl );
    foreach my $check ( @expected_labels ) { 
      ok( (any { $_ eq $check } @labels),
          "$test_name: $check in labels for $name" );
    }
  }
}

done_testing();


