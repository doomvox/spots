# Perl test file, can be run like so:
#   perl 14-Spots-Rectangle-is_overlapping-check_placed.t
#          doom@kzsu.stanford.edu     2019/04/07 16:32:05

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
  use_ok( 'Spots::Rectangle' , );
  use_ok( 'Spots::Rectangle::TestData', ':all' );  
}

ok(1, "Traditional: If we made it this far, we're ok.");

{ no warnings 'once'; $DB::single = 1; }



{  my $subname = "check_placed_overunroll_corrected";
   my $test_name = "Testing $subname";
   my $placed_grendel1 = generate_placed_grendel1();
   my @placed = @{ $placed_grendel1 }; 
   my $report = check_placed_overunroll_corrected( \@placed );
   isnt( $report, '', "$test_name: the cat 2 & 4 overlap should be detected" )
     or say STDERR $report;
 }

{  my $subname = "check_placed_isoverlapping_unrolled";
   my $test_name = "Testing $subname";
   my $placed_grendel1 = generate_placed_grendel1();
   my @placed = @{ $placed_grendel1 }; 
   my $report = check_placed_isoverlapping_unrolled( \@placed );
   isnt( $report, '', "$test_name: the cat 2 & 4 overlap should be detected" )
     or say STDERR $report;
 }


{
   my $class_exp = "Spots::Homepage::Layout::MetacatsFanout";
   my $test_name = "Testing ";

   my $placed_grendel1 = generate_placed_grendel1();

   my @placed = @{ $placed_grendel1 }; 

   my $a = $placed[2];     # cat 2
   my $b = $placed[3];     # cat 4 

   # Note, the cat 4 data has no x/y fields instantiated yet,
   # because it was placed first without the lazy accessors
   # called that would populate the fields from the coords field.
   # Here we verify that an is_overlapping check on $b (cat 4)
   # does create the fields.

   my @cat_4_fields = sort keys( %{ $b } );
   my @expected_cat_4_fields = ( 'coords', 'meta', 'y_weight', );
   is_deeply( \@cat_4_fields, \@expected_cat_4_fields, "Testing cat 4: no x/y fields yet");

   ok ( not( $a->is_overlapping( $b ) ) , "Testing is_overlapping: overlap found on problem case: cat id 2 & 4" );

   @cat_4_fields = sort keys( %{ $b } );
   @expected_cat_4_fields = sort ( 'coords', 'meta', 'y_weight', 'x1', 'x2', 'y1', 'y2', );

   is_deeply( \@cat_4_fields, \@expected_cat_4_fields, "Testing cat 4: x/y fields instantiated");
}

{  my $subname = "check_placed (simulated)";
   my $test_name = "Testing $subname";
   my $placed_grendel1 = generate_placed_grendel1();
   my @placed = @{ $placed_grendel1 }; 
   my $report = check_placed_simulated( \@placed );
   isnt( $report, '', "$test_name: the cat 2 & 4 overlap should be detected" )
     or say STDERR $report;
 }



done_testing();


### end main, into the subs

=head2 subs

=over 

=item check_placed_simulated

=cut

sub check_placed_simulated {
  my $placed = shift;
  my @placed = @{ $placed };

  my $report = '';
  foreach my $i ( 0 .. $#placed ) { 
    foreach my $j ( $i+1 .. $#placed ) { 

#      say STDERR " i: $i, j: $j "; # DEBUG
      my $a = $placed->[ $i ];
      my $b = $placed->[ $j ];

      my ($a_id, $b_id)     = ($a->meta->{cat},      $b->meta->{cat});
      my ($a_name, $b_name) = ($a->meta->{cat_name}, $b->meta->{cat_name});

      if ( $a->is_overlapping( $b ) ) {  
        # report the problem
        my $a_coords = $a->coords;
        my $b_coords = $b->coords;

        my $mess = "Overlap: \n";
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $a_id, $a_name, @{ $a_coords };
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $b_id, $b_name, @{ $b_coords };
        # ($DEBUG) && say STDERR $mess, "\n";
        $report .= $mess;
      }
    }
  }
  return $report;
}



=item check_placed_isoverlapping_unrolled

=cut

sub check_placed_isoverlapping_unrolled {
  my $placed = shift;
  my @placed = @{ $placed };

  my $report = '';
  foreach my $i ( 0 .. $#placed ) { 
    foreach my $j ( $i+1 .. $#placed ) { 

      my $a = $placed->[ $i ];
      my $b = $placed->[ $j ];

      my ($a_id, $b_id)     = ($a->meta->{cat},      $b->meta->{cat});
      my ($a_name, $b_name) = ($a->meta->{cat_name}, $b->meta->{cat_name});

      my( $ax1, $ay1, $ax2, $ay2 ) = ( $a->x1, $a->y1, $a->x2,  $a->y2 );
      my( $bx1, $by1, $bx2, $by2 ) = ( $b->x1, $b->y1, $b->x2,  $b->y2 );

      my $non_overlap = 
        ($ax1 < $bx1  && $ax2 < $bx2)
        || ($ax1 > $bx1  && $ax2 > $bx2)
        || ($ay1 < $by1  && $ay2 < $by2)
        || ($ay1 > $by1  && $ay2 > $by2);

      my $overlap = not( $non_overlap );

      printf STDERR "i: %d %10s: %4d   j: %d %10s: %4d  => %d\n", $i,
                        $a_name, $a_id, $j, $b_name, $b_id, ($overlap+0); # DEBUG
      if ( $overlap ) {  
        # report the problem
        my $a_coords = $a->coords;
        my $b_coords = $b->coords;

        my $mess = "Overlap: \n";
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $a_id, $a_name, @{ $a_coords };
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $b_id, $b_name, @{ $b_coords };
        # ($DEBUG) && say STDERR $mess, "\n";
        say STDERR $mess, "\n";
        $report .= $mess;
      }
    }
  }
  return $report;
}

=item check_placed_overunroll_corrected

=cut

sub check_placed_overunroll_corrected {
  my $placed = shift;
  my @placed = @{ $placed };

  my $report = '';
  foreach my $i ( 0 .. $#placed ) { 
    foreach my $j ( $i+1 .. $#placed ) { 

      my $a = $placed->[ $i ];
      my $b = $placed->[ $j ];

      my ($a_id, $b_id)     = ($a->meta->{cat},      $b->meta->{cat});
      my ($a_name, $b_name) = ($a->meta->{cat_name}, $b->meta->{cat_name});

      my( $ax1, $ay1, $ax2, $ay2 ) = ( $a->x1, $a->y1, $a->x2,  $a->y2 );
      my( $bx1, $by1, $bx2, $by2 ) = ( $b->x1, $b->y1, $b->x2,  $b->y2 );

#       my $non_overlap = 
#         ($ax1 < $bx1  && $ax2 < $bx2)
#         || ($ax1 > $bx1  && $ax2 > $bx2)
#         || ($ay1 < $by1  && $ay2 < $by2)
#         || ($ay1 > $by1  && $ay2 > $by2);

      my $non_overlap = 
        ($by1 > $ay2) || ($bx1 > $ax2) || ($bx2 < $ax1) || ($by2 < $ay1);

      my $overlap = not( $non_overlap );

      printf STDERR "i: %d %10s: %4d   j: %d %10s: %4d  => %d\n", $i,
                        $a_name, $a_id, $j, $b_name, $b_id, ($overlap+0); # DEBUG
      if ( $overlap ) {  
        # report the problem
        my $a_coords = $a->coords;
        my $b_coords = $b->coords;

        my $mess = "Overlap: \n";
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $a_id, $a_name, @{ $a_coords };
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $b_id, $b_name, @{ $b_coords };
        # ($DEBUG) && say STDERR $mess, "\n";
        say STDERR $mess, "\n";
        $report .= $mess;
      }
    }
  }
  return $report;
}






=back 

=cut 


