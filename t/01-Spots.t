# A perl test file, which can be run like so:
#    perl 01-Spots.t
#         doom@kzsu.stanford.edu     2019/03/28 13:41:14

use 5.10.0;
use warnings;
use strict;
$|=1;
my $DEBUG = 1;             # TODO set to 0 before ship
use Data::Dumper;

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

my $class;
BEGIN {
  $class = 'Spots';
  use_ok( $class );
#  $DB::single = 1;
}

{ my $test_name = "Testing creation of object of expected type: $class";
  my $obj = $class->new();
  my $created_class = ref $obj;
  is( $created_class, $class, $test_name );
}

# Insert your test code below.



done_testing();
