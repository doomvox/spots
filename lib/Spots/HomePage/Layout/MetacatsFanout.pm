package Spots::HomePage::Layout::MetacatsFanout;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::HomePage::Layout::MetacatsFanout - cats with spots in colonies called metacats, arranged on an html page

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::HomePage::Layout::MetacatsFanout;
   my $lo = 
       Spots::HomePage::Layout::MetacatsFanout->new({ dbname => $dbname });

   # TODO expand on this

=head1 DESCRIPTION

Spots::HomePage::Layout::MetacatsFanout is a module that uses a particullar
"layout style" to generate an html "homepage" full of links grouped in 
categories and metacategories (cats and metacats). 

The information describing the cats with spots is read from the "spots" 
database, and the rectangular layout generated is written to the "layout" 
table in the form of x/y location values.  

TODO this is a "standalone" layout generator that handles a particular 
experimental style (called "metacats fanout").  Eventually it should 
probably be refactored to make it easier to swap in different styles.

=head1 METHODS

=over

=cut

use 5.10.0;
no warnings 'experimental';
use Carp;
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use autodie         qw( :all mkpath copy move ); # system/exec along with open, close, etc
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );
use String::ShellQuote qw( shell_quote );

use Spots::DB::Handle;
use Spots::Rectangle;
use Spots::Category;
use Spots::Herd;


=item new

Creates a new Spots::HomePage::Layout::MetacatsFanout object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

{ no warnings 'once'; $DB::single = 1; }

has debug  => (is => 'rw', isa => Bool, default => sub{return ($DEBUG||0)});

has dbname => (is => 'rw', isa => Str, default => 'spots' );

has dbh    => (is => 'rw', isa => InstanceOf['DBI::db'],
               lazy => 1, builder => 'builder_db_connection' );

has top_bound   => (is => 'ro', isa => Num, default => 0 );
has left_bound  => (is => 'ro', isa => Num, default => 0 );
has bot_bound   => (is => 'ro', isa => Num, default => 10000 );  # big numbers for now
has right_bound => (is => 'ro', isa => Num, default => 10000 );

# default values empirically determined
has vertical_scale     => (is => 'rw', isa => Num,  default => 1.3 ); # rem per line
has horizontal_scale   => (is => 'rw', isa => Num,  default => 12  ); # px per char

has vertical_padding   => (is => 'rw', isa => Num,  default => 2   );  # rem
has horizontal_padding => (is => 'rw', isa => Int,  default => 10  );  # px 

# used by metacats_fanout, find_hole_for_cat_thataway
has nudge_x   => (is => 'rw', isa => Num,  default => 1.5 );  # rem
has nudge_y   => (is => 'rw', isa => Int,  default => 6   );  # px 

has initial_y => (is => 'rw', isa => Int,  default => 0    ); # rem 
has initial_x => (is => 'rw', isa => Int,  default => 5    ); # px

has layout_style => (is => 'rw', isa => Str, default => 'metacats_fanout' ); 

# array of rectangles added to the current layout (used by 'metacats_fanout')
has placed       => (is => 'rw', isa => ArrayRef, default => sub{ [] } );

has cat_herder => (is => 'rw', isa => InstanceOf['Spots::Herd'], lazy=>1,
                   builder => 'builder_cat_herder' );

has all_cats   => (is => 'rw', isa => ArrayRef[InstanceOf['Spots::Category']],
                   lazy=>1, builder => 'builder_all_cats' );




=item builder_db_connection

=cut

sub builder_db_connection {
  my $self = shift;

  # TODO  use Spots::DB::Handle
  my $dbname = $self->dbname; # default 'spots'
  # my $port = '5434'; # non-standard port for old build on tango
  my $port = '5432';
  my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
  my $username = 'doom';
  my $auth = '';
  my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
  my $dbh = DBI->connect($data_source, $username, $auth, \%attr);

  return $dbh;
}


=item builder_cat_herder

=cut

sub builder_cat_herder {
  my $self = shift;
  my $dbname = $self->dbname;
  my $herd = Spots::Herd->new( dbname => $dbname ); 
  return $herd;
}

=item builder_all_cats

=cut

sub builder_all_cats {
  my $self = shift;
  my $cat_herder = $self->cat_herder;
  my $all_cats = $cat_herder->cats;
  return $all_cats
}

=item clear_placed

=cut

sub clear_placed {
  my $self = shift;
  @{ $self->{ placed } } = ();
}

=back

=head2 layout generation

Determine placement of cats, writing x, y, width, and height
the the layout table. 

=over 

=item clear_layout

Blank out the coordinate columns in the layout table:
  x_location, y_location, width, height

Safety feature: this will only work if dname contains string "test".
TODO that suggests it should be in a package of Test utitlites.

=cut

sub clear_layout {
  my $self = shift;

  my $dbname = $self->dbname;
  unless( $dbname =~ /test/ ) {
    croak "clear_layout will only work on a DATABASE named with 'test'";
  }

  my $update_sql = 
    qq{UPDATE layout } .
    qq{SET x_location=NULL, y_location=NULL, width=NULL, height=NULL } ;

  my $dbh = $self->dbh;
  my $rows_affected = 
    $dbh->do( $update_sql );
  # $dbh->commit;  # even though AutoCommit is on
  return $rows_affected;
}




# =item cat_size_to_layout

# Determine the height (in rem) and width (in px) of each cat, and
# write it to the layout table.

# Defaults to all cats, can be over-ridden by passing an aref of 
# Category objects.

# =cut

# sub cat_size_to_layout {
#   my $self = shift;
# #  my $cats = shift || $self->list_all_cats(); 
#   my $cats = shift || $self->all_cats();

#   my $cat_count = scalar( @{ $cats } );

#   my $popcat = 0; # count of populated cats, i.e. ones with spots
#  CAT:
#   foreach my $cat ( @{ $cats } ) { 
#     # my $cat_id   = $cat->{ id };
#     # my $cat_name = $cat->{ name };
#     my $cat_id   = $cat->id;
#     my $cat_name  = $cat->name;

#     my $cat_spots  = $cat->spots;
#     my $spot_count = $cat->spot_count;
#     my $x          = $cat->x_location;
#     my $y          = $cat->y_location;
#     my $w          = $cat->width;
#     my $h          = $cat->height;

#     # my ($cat_spots, $height_in_lines) = $self->lookup_cat( $cat_id );  
# #    my $height_in_lines = $spot_count;
#     next CAT if not $cat_spots; # skip empty category
#     $popcat++;
# #     my $width_chars = $self->cat_width( $cat_spots );
# #     my ($height_rem, $width_px) =
# #       $self->cat_dimensions( $height_in_lines, $width_chars );

# #    $self->update_height_width_of_cat( $cat_id, $width_px, $height_rem );
#     $self->update_height_width_of_cat( $cat_id, $w, $h );
#   }
#   if( $popcat < $cat_count ) {
#     my $empties = $cat_count - $popcat;
#     carp "There are $empties cats without spots.";
#   }
#   return $popcat;
# }

=item generate_layout

Use the spots/category tables to generate a layout scheme,
saving the coordinates to the layout table.

Takes one optional argument, a string to specify a layout style.

  'by_size'  - the original proof of concept, linear by size of category  
  'metacats' - adding another level of classification, grouping the categories
  'metacats_doublezig'
             - like metacats with layout with an additional top-to-bottom
               zig-zag inside the usual T-to-B/L-to-R.

  'metacats_fanout'
             - start in corner, move outwards, uses collision detection.

=cut

sub generate_layout {
  my $self = shift;
  my $style = shift || $self->layout_style;
  $self->hello_sub("style: $style");

#   # general setup
#   # moving here, despite redundant 'list_all_cats'  TODO cache cats in object
#   my $cats = $self->list_all_cats( $style ); 
#   $self->cat_size_to_layout( $cats );  # populate h & w fields

  my $method = "generate_layout_$style";
  my $ret = $self->$method;
  $self->farewell();
  return $ret;
}


=item generate_layout_metacats_fanout

EXPERIMENTAL

This routine:

Roughly: starts in the upper left corner, and move outwards
from there, in "random" directions, using a collision detection
routine to tighten up placement.

Really the "random" directions just *look* random: they're the
behavior is deterministic for any given input to facillitate
testing.

Specifcally (at present): 

For each cat, we generate a list of candidate locations where the
next cat might be placed then evaluate them and choose one.  The
candidates are generated by beginning with some recently placed
rectangles, and looking in four directions from there ('n', 's',
'e', 'w') for the next open space where the given cat can fit.
The starting locations are the last three placed rectangles
(check).  We find open space by checking a potential location for
overlaps with *each* of the placed rectangles, using the
rectangle's is_overlapping method.  If an overlap is discovered, 
we move over far enough to clear the overlapped rectangle, and 
try again.

The method of evaluating candidate locations is not set: it's
currently just a stub that tries to choose the third out of the 
list (or failing that the second or first). 

STATUS: the "is_overlapping" routine is *not* buggy, but something 
about the way it's used here generates layouts with some overlaps. 
This is slightly puzzling.


=cut

sub generate_layout_metacats_fanout {
  my $self = shift;
  # my $cats = shift || $self->list_all_cats(); 
  my $cats = shift || $self->all_cats();
  my $cat_count = scalar( @{ $cats } );
  $self->hello_sub("cat_count: $cat_count");

  unless( $cat_count > 0 ) {
    croak "Sadly, we have no cats, we can not 'generate_layout_metacats_fanout'";
  }

  # initialize $placed array: place the first cat in upper-left
  $self->clear_placed;
#  my $placed = $self->placed;
  my ($x1, $y1) = ($self->initial_x, $self->initial_y);
  my $cat = shift @{ $cats };  
  $self->put_cat_in_place( $cat, $x1, $y1 );   # $cat is now a Category object TODO...
 CAT:
  foreach my $cat ( @{ $cats } ) { 
#    my $cat_spots = $self->count_cat_spots( $cat ); # implicit fill_in_cat
    my $cat_spots  = $cat->spots;
    next CAT if not $cat_spots; # skip empty category

    my ($x1, $y1) = $self->find_place_for_cat( $cat );  # $cat is now a Category object TODO...
    $self->put_cat_in_place( $cat, $x1, $y1 );
  }
  my $place_count = scalar( @{ $self->placed } );
  $self->farewell();
  return $place_count; 
}


=item create_rectangle

Returns a rectangle object at the given point, with given width and height.

Example use:

  my $first_rect = 
    $self->create_rectangle( $x1, $y1, $width, $height );

=cut

sub create_rectangle {
  my $self = shift;
  my $x1     = shift;
  my $y1     = shift;
  my $width  = shift;
  my $height = shift;

  confess("create_rectangle: need x1 and y1") unless ( defined( $x1 ) && defined( $y1 ) );
  confess("create_rectangle: height and width must be non-zero") unless ($height>0 && $width>0) ;

  my $x2 = $x1 + $width;
  my $y2 = $y1 + $height;
  my $rect = Spots::Rectangle->new({ coords => [ $x1, $y1, $x2, $y2 ] });  
  return $rect;
}

=item create_rectangle_for_cat

Given a $cat and an x1/y1 point, returns a new rectangle object
for it.  If need be fill_in_cat is called to get height and width.

  my $rect = 
    $self->create_rectangle_for_cat( $cat, $x1, $y1  );

=cut

sub create_rectangle_for_cat {
  my $self = shift;
  my $cat  = shift;
  my $x1   = shift;
  my $y1   = shift;
  #  my ($width, $height) = $self->cat_width_height( $cat );
  my $width  = $cat->width;
  my $height = $cat->height;

  my $x2 = sprintf( "%.f",  ($x1 + $width ))    + 0;  # played with forcing numeric: no effect
  my $y2 = sprintf( "%.f",  ($y1 + $height ))   + 0;

  my $rect = Spots::Rectangle->new({ coords => [ $x1, $y1, $x2, $y2 ] });  
  return $rect;
}


=item find_place_for_cat

pick location for cat, avoid collision with anything in placed.
also stash cat in "placed" data structure

Example usage:

      my ($x1, $y1) = $self->find_place_for_cat( $cat )

=cut

# find a place to put the given cat in the layout
sub find_place_for_cat {
  my $self       = shift;
  my $cat        = shift;   
  my $placed     = shift || $self->placed;  # aref of rectangles
#  my $cat_name = $cat->{ name };
  my $cat_id     = $cat->id;
  my $cat_name   = $cat->name;
#  my $mc_id    = $cat->{ metacat };
  my $mc_id      = $cat->metacat_id;

  $self->hello_sub("cat: " . $cat_id . ' ' . $cat_name);

  # We start at an already placed rectangle (the "starting rectangle")
  # and look from there in various directions.

  # choose possible starting points from already placed rects 
  my @start_rects;
  my @placed_from_mc = grep { $_->metacat == $mc_id } @{ $placed }; 

  if( @placed_from_mc ) { 
    @start_rects = @placed_from_mc;
  } else { # if none yet placed from this metacat, just use the most recent
    # @start_rects = @{ $placed }[ -3 .. -1 ];

    push @start_rects, $placed->[ -1 ];
    push @start_rects, $placed->[ -2 ] if defined $placed->[ -2 ];
    #  push @start_rects, $placed->[ -3 ] if defined $placed->[ -3 ];
  }

  my $candidate_locations = 
     $self->look_all_around_given_rectangles( \@start_rects, $cat );
  # $self->candidate_dumper( $candidate_locations );  # missing method now
  
  my $coords = $self->evaluate_candy( 'LAST_ONE', $candidate_locations ); # STUB
  my ( $x1, $y1 ) = @{ $coords } if $coords;

  $self->farewell();
  return ( $x1, $y1 );
}


=item evaluate_candy

A collection of experimental stubs, something simple to fill in
the gaps for now.

=cut

sub evaluate_candy {
  my $self = shift;
  my $evaluation_method = shift;
  my $candidate_locations = shift;
  state $i;  # my first use of "state"
  my $coords;
  given( $evaluation_method ) {
    when (/^LAST_ONE$/)
      {
        $coords = $candidate_locations->[ -1 ]
        }
    when (/^RANDOM$/)
      {
        $coords = 
          $candidate_locations->[ int( rand( $#{ $candidate_locations } ) + 0.5 ) ]
        }
    when (/^FIRST_ONE$/)
      {
        $coords = $candidate_locations->[ 0 ];
      }
    when (/^THREE_TWO_ONE$/)
      {
        my @first_three = @{ $candidate_locations }[ 0 .. 2 ];
        my $pick;
      MAYBE: 
        foreach my $maybe ( reverse @first_three ) { 
          if ( $maybe ) { 
            $pick = $maybe;
            last MAYBE;
          }
        }
        $coords = $pick;
      }
    when (/^THREE_CYCLE$/)
      { if ( $i ) { 
        $i = 0 if $i == 2;
        $i = 1 if $i == 0;
        $i = 2 if $i == 1;
      } else {
        $i = 2; 
      }
        my $lim = $#{ $candidate_locations };
        $i = $lim if( $i > $lim );
        $coords = $candidate_locations->[$i];
      }
    default { 
      die "Must define $evaluation_method as something known";
    }
  };
  return $coords;
}

=item put_cat_in_place

Given $cat href, an x & y location 
puts an appropriate rectangle object in the object's @placed array, 
and also updates the position in the layout table.

Example usage:

  $self->put_cat_in_place( $cat, $x1, $y1 );

=cut

sub put_cat_in_place {
  my $self    = shift;
  my $cat     = shift;
  my $x1      = shift;
  my $y1      = shift;
  my $placed  = $self->placed;
  my $placed_count = scalar( @{ $placed } );
  $self->hello_sub("placed count: " . $placed_count );

  #  newly choosen x, y values added to the $cat
  $cat->x_location( $x1 );
  $cat->y_location( $y1 );  

  my $w    = $cat->width;
  my $h    = $cat->height;
  my $rect = 
    $self->create_rectangle( $x1, $y1, $w, $h );

  # stash cat stuff in meta info for the rectangle
  my $rect_meta_info = $rect->meta;
  $rect_meta_info->{cat}          = $cat->id;
  $rect_meta_info->{metacat}      = $cat->metacat_id;
  $rect_meta_info->{cat_name}     = $cat->name;
  $rect_meta_info->{metacat_name} = $cat->metacat_name;

  push @{ $placed }, $rect;

  my $ret = 
    $self->update_layout_for_cat( $cat, $x1, $y1 ); # save x,y,h,w to database

  $self->farewell();
  return $ret;
}


=item ungoodness

Compute an "ungoodness" parameter for an association between two
rectangles (Spots::Rectangle objects).  A "good" association is
one that makes sense when doing a graphical layout.  At present,
"ungoodness" is just the geometric center-to-center distance
between the rectangles-- the smaller the better.

Example use:

 $param = 
   $self->ungoodness( $candidate_rectangle, $last_rectangle );

TODO 

The second parameter is going to become optional (or more likely vestigial).

Evaluating the candidate_rectangle is done by computing the distances 
between it and the other already placed cats of the same metacat.

=cut

sub ungoodness {
  my $self = shift;
  my $r1 = shift;
  my $r2 = shift;

  my $mc = $r1->metacat;
  my $placed = $self->placed;

  say "WARNING: got no metacat info for this rect" unless $mc;

  my @same_metacat;
  { no warnings 'uninitialized';
    @same_metacat = grep { $_->metacat == $mc } @{ $placed };
  }

  # TODO: vector summation?
  my ($dist, $total);
  foreach my $other ( @same_metacat ) {
    $dist = $r1->distance( $other );
    $total += $dist;
  }
  
  # my $cat_name = $r1->{meta}->{cat_name};
  # say "$cat_name of metacat: $mc has distance total: $total";

  $dist = $total;
  return $dist;
}



=item check_placed

Goes through the placed rectangles, looking for mistakes where
two rectangles overlap.  Returns a copy of the report, 
but if $DEBUG is on, it also reports directly to STDERR.

Example usage:

   my $report = $self->check_placed();

=cut

sub check_placed {
  my $self = shift;
  my $placed = shift || $self->placed;

  my $report = '';
  foreach my $i ( 0 .. $#{ $placed } ) { 
    foreach my $j ( $i+1 .. $#{ $placed } ) { 
      my $a = $placed->[ $i ];
      my $b = $placed->[ $j ];

      my $a_meta = $a->meta;
      my $b_meta = $b->meta;

      my $a_name = $a_meta->{cat_name};
      my $a_id   = $a_meta->{cat};

      my $b_name = $b_meta->{cat_name};
      my $b_id   = $b_meta->{cat};

      if( $a->is_overlapping( $b ) ) {  
        # report the problem
        my $a_coords = $a->coords;
        my $b_coords = $b->coords;

        my $mess;
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $a_id, $a_name, @{ $a_coords };
        $mess .= sprintf "%4d %13s: %d,%d  %d,%d\n", $b_id, $b_name, @{ $b_coords };
        ($DEBUG) && say STDERR $mess, "\n";
        $report .= $mess;
      }
    }
  }
  return $report;
}




=item look_all_around_given_rectangles

Given at least one starting rectangle, look around the edges for
an open area that will fit the given category.  Return a list of
some (x, y) pairs that would work.  Note: it need not be an
exhaustive list.  It can include places not *immediately*
adjacent to the given starting rectangle.

Returns a list of arefs of x, y pairs.

  my $candidate_locations = 
    $self->look_all_around_given_rectangles( \@start_rects, $cat );

The idea is since we know where placed rectangles are, might as
well start next to them, and if there's an overlap, use the
*overlapped* rect to find where to look next for an open area.

TODO  Ideally, better locations should be stuck closer to
      the top of list of candidates_locations.  

=cut

sub look_all_around_given_rectangles {
  my $self = shift;
  my $start_rects = shift;
  my $cat = shift;
#  $self->hello_sub("looking for place for cat: " . $cat->{id} . ' ' . $cat->{name});
  $self->hello_sub("looking for place for cat: " . $cat->id . ' ' . $cat->name);

  my ($width, $height) = ($cat->width, $cat->height);

### TODO px vs rem? 
#   my $inc_x = 1; 
#   my $inc_y = 1; 
  my $inc_x = 4;
  my $inc_y = 0.5;

  my @candilocs;
  my $placed    = $self->placed;

  my ($x_trial, $y_trial, $newplc);
  foreach my $sr ( @{ $start_rects } ) { 
    my ($x1, $y1) = ($sr->x1, $sr->y1);
    my ($x2, $y2) = ($sr->x2, $sr->y2);

    # east
    ($x_trial, $y_trial) = ($x2+$inc_x, $y1);
    $newplc =
      $self->find_hole_for_cat_thataway( 'e', $cat, $x_trial, $y_trial, $placed );
    push @candilocs, $newplc if $newplc;

    # west
    ($x_trial, $y_trial) = ($x1-($width+$inc_x), $y1);
    $newplc =
      $self->find_hole_for_cat_thataway( 'w', $cat, $x_trial, $y_trial, $placed );
    push @candilocs, $newplc if $newplc;

    # south 
    ($x_trial, $y_trial) = ($x1, $y2+$inc_y);
    $newplc =
      $self->find_hole_for_cat_thataway( 's', $cat, $x_trial, $y_trial, $placed );
    push @candilocs, $newplc if $newplc;

    # north
    ($x_trial, $y_trial) = ($x1, ($y1-($height+$inc_y)));
    $newplc =
      $self->find_hole_for_cat_thataway( 'n', $cat, $x_trial, $y_trial, $placed );
    push @candilocs, $newplc if $newplc;
  }

  my $mess = '';
  # my $mess = defined( $new_rect ) ?  "returning rectangle" : "returning undef";
  $self->farewell( $mess );
  return \@candilocs;
}



=item find_hole_for_cat_thataway

Find open place for $cat looking over that way (in direction: 'e', 'w', 's', 'n'),

 o  starting from here: $x, $y

 o  avoid overlaps with rectangles in aref $placed 
     (defaults to object's "placed")

Example usage:  

  my $adds = $self->find_hole_for_cat_thataway( 'e', $cat, $x, $y, $placed );
  push @candilocs, @{ $adds };

=cut

sub find_hole_for_cat_thataway {
  my $self      = shift;
  my $direction = shift; 
  my $cat       = shift;  # once an href, now a Category object...
  my $x_trial   = shift;
  my $y_trial   = shift; 
  my $placed    = shift || $self->placed;
  $self->hello_sub("Looking in direction: $direction to find hole for cat: " . $cat->{id} . ' ' . $cat->{name});

  # check if $x_trial and/or $y_trial are out-of-bounds, i.e. less than 0.
  return () if( ($x_trial < 0) || ($y_trial < 0) );

  my @additional_places;

  # Given a $cat and a tentative x,y to start we create a rectangle for the cat on the fly, 
  # and check for overlap against each of the already placed rectangles.
  # If we hit an overlap, we get the size of the overlapped 
  # rectangle, move our tentative x,y past it moving in $direction,
  # and restart the check against the "gauntlet" of placed rectangles.
  # When we've got a position that clears all of them, we use that.

  my ($x, $y) = ($x_trial, $y_trial);
  my $boxed_cat = $self->create_rectangle_for_cat( $cat, $x, $y  );
 GAUNTLET: {
      foreach my $placed_rect ( @{ $placed } ) { 
        if ( $boxed_cat->is_overlapping( $placed_rect ) ) {  
          # step around overlapped rectangle, try again
          ($x, $y) =
            $self->step_passed_rectangle( $x, $y, $direction, $placed_rect, $boxed_cat );
          return undef if $self->position_out_of_bounds( $x, $y );
          $boxed_cat = $self->create_rectangle_for_cat( $cat, $x, $y ); # new rect to run gauntlet
          redo GAUNTLET; # restart check against list of placed
        } 
       } # end foreach
  }
  my $new_place = [ $x, $y ];
  $self->farewell();
  return $new_place;
}

=item step_passed_rectangle

Example usage:

  my ($new_x, $new_y) = 
    $self->step_passed_rectangle( $x, $y, $direction, $placed_rect, $boxed_cat );

=cut

sub step_passed_rectangle {
  my $self      = shift;
  my $x         = shift;
  my $y         = shift;
  my $direction = shift;
  my $rect      = shift;  # move passed this one, the placed_rect
  my $fit_rect  = shift;  # but need room to squeeze in this one, the boxed_cat

  my $nudge_x   = shift || $self->nudge_x;
  my $nudge_y   = shift || $self->nudge_y;

  # when going 'n' or 'w' have to move the (x,y) point far enough to fit in this rect
  my $w = $fit_rect->width;
  my $h = $fit_rect->height;

  if ( $direction eq 'e' ) { 
    $x = $rect->x2 + $nudge_x;
  } elsif ( $direction eq 'w' ) {
    $x = $rect->x1 - $nudge_x - $w;
  } elsif ( $direction eq 's' ) {
    $y = $rect->y2 + $nudge_y;
  } elsif ( $direction eq 'n') {
    $y = $rect->y1 - $nudge_y - $h;
  } else {
    croak "direction needs to be one of 'e', 'w', 's', or 'n'";
  }
  return ($x, $y);
}



=item position_out_of_bounds

Example usage:

   return undef if( $self->position_out_of_bounds( $x, $y ) );

=cut

sub position_out_of_bounds {
  my $self = shift;
  my $x = shift;
  my $y = shift;
  $self->hello_sub("checking point ($x, $y)");

  my $top_bound   = $self->top_bound || 0;
  my $left_bound  = $self->left_bound || 0; 
  my $bot_bound   = $self->bot_bound;
  my $right_bound = $self->right_bound;

  my $out;
  if( ( $x < $left_bound || $x > $right_bound ) ||
      ( $y < $top_bound  || $y > $bot_bound )      
    ) {
    $out = 1;
  } else {
    $out = 0;
  }
  $self->farewell("out?: $out");
  return $out;
}


# =item cat_width

# Example usage:

#     my $width_in_chars = $self->cat_width( $cat_spots );

# =cut

# # CAT
# sub cat_width {
#   my $self = shift;
#   my $cat_spots = shift;

#   my $max_chars = 0;
#   # for each link line in a cat rectpara
#   foreach my $spot ( @{ $cat_spots } ) {
#     my $url     =  $spot->{ url };
#     my $label   =  $spot->{ label };
#     my $spot_id =  $spot->{ id };

#     my $chars = length( $label );
#     if ( $chars > $max_chars ) {
#       $max_chars = $chars;
#     }
#   }
#   return $max_chars;
# }

=item initialize_layout_table_with_cats

As currently written, the layout table needs to be initialized
with all the category.id values.  (Hack, hack.)

=cut

sub initialize_layout_table_with_cats {
  my $self = shift;
  my $dbh = $self->dbh;
  my $sql =
    qq{ INSERT INTO layout (category) SELECT id FROM category };
  $dbh->do( $sql );
}


# =item update_height_width_of_cat

# Store the layout information for a particular cat.

# Example usage:

#   $self->update_height_width_of_cat( $cat_id, $width, $height );

# =cut

# # TODO eventually, fold this into update_layout_for_cat, no need to do this early
# sub update_height_width_of_cat {
#   my $self   = shift;
#   my $cat_id = shift;
#   my $width  = shift;
#   my $height = shift;

#   my $sql_update = $self->sql_to_update_height_width();
#   # UPDATE layout SET width=?, height=? WHERE category = ?

#   my $dbh = $self->dbh;

#   my $sth = $dbh->prepare( $sql_update );  # TODO stash prepared sth (maybe)
#    $sth->execute( $width, $height, $cat_id ); 
#   return;
# }


=item update_layout_for_cat

Store the layout information for a particular cat.

Example usage:

  $self->update_layout_for_cat( $cat, $x, $y );  # takes a Category object

=cut

sub update_layout_for_cat {
  my $self   = shift;
  my $cat    = shift;
  my $x      = shift;  # the x/y values *are* in $cat, but not sure I like that feature.
  my $y      = shift;

  my $cat_id = $cat->id;
  my $w      = $cat->width;
  my $h      = $cat->height;

  $self->hello_sub("cat_id: $cat_id x: $x, y: $y, w: $w, h: $h");

  $x = sprintf "%.0f", $x;
  $y = sprintf "%.0f", $y;
  $w = sprintf "%.0f", $w;

  my $upsert_sql = $self->sql_to_update_layout();
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare( $upsert_sql );  
  $sth->execute( $cat_id, $x, $y, $w, $h, $x, $y, $w, $h ); # yeah, I know

  say STDERR "error: ", $sth->errstr if $sth->err;
  $self->farewell();
  return;
}


# =item update_layout_for_cat

# Store the layout information for a particular cat.

# Example usage:

#   $self->update_layout_for_cat( $cat_id, $x, $y, $width, $height );

# =cut

# sub update_layout_for_cat_OLD {
#   my $self   = shift;
#   my $cat_id = shift;
#   my $x      = shift;
#   my $y      = shift;
#   my $width  = shift;
#   my $height = shift;

#   $x      = sprintf "%.0f", $x;
#   $y      = sprintf "%.0f", $y;
#   $width  = sprintf "%.0f", $width;
#   $height = sprintf "%.1f", $height;

#   my $sql_update =
#     $self->sql_to_update_layout( $cat_id, $x, $y, $width, $height );

#   my $dbh = $self->dbh;
#   my $rows_affected = 
#     $dbh->do( $sql_update );
#   # $dbh->commit;  # even though AutoCommit is on
#   return $rows_affected;
# }




=item sql_to_update_height_width

  my $sql_update = $self->sql_to_update_height_width()

=cut

sub sql_to_update_height_width {
  my $self       = shift;
  my $update_sql =<<"__END_SKULL_UHW";
    UPDATE layout SET width = ?, height = ? WHERE category = ?
__END_SKULL_UHW
  return $update_sql;
}

# =item sql_to_update_x_y

#   my $sql_update = $self->sql_to_update_x_y()

# =cut

# sub sql_to_update_x_y {
#   my $self       = shift;
#   my $update_sql =<<"__END_SKULL_UHW";
#     UPDATE layout SET x_location=?, y_location=? WHERE category = ?
# __END_SKULL_UHW
#   return $update_sql;
# }


=item sql_to_update_layout

  my $upsert_update = $self->sql_to_update_layout();

The sql requires nine bind-params, four duplicated: 

  $cat_id, $x, $y, $w, $h, $x, $y, $w, $h

=cut

sub sql_to_update_layout {
  my $self       = shift;

  #### TODO switch this over to a prepared statement handle?

  # id | category | x_location | y_location | height | width 
  my $update_sql = 
  qq{ INSERT INTO layout (category, x_location, y_location, width, height) 
      VALUES (?,?,?,?,?)
      ON CONFLICT (category) 
      DO 
        UPDATE
          SET x_location = ?, y_location = ?, width = ?, height = ? };

  return $update_sql;
}


=back 

=head3 debuggery

=over 

=item hello_sub

=cut

sub hello_sub {
  my $self = shift;
  my $msg     = shift;  # describing/sampling args 

  my $debug = $DEBUG || $self->debug;

  my $package = ( caller(1) )[0];
  my $sub     = ( caller(1) )[3];

  (my $just_sub = $sub) =~ s/^ $package :://x;

  my $output  = "call: $just_sub";
  $output .= " with $msg" if $msg;

  # $output .= " $package";
  print STDERR "$output\n" if $debug;
}



=item farewell

=cut

sub farewell {
  my $self = shift;
  my $msg  = shift;

  my $debug = $DEBUG || $self->debug;

  my $package = ( caller(1) )[0];
  my $sub     = ( caller(1) )[3];

  (my $just_sub = $sub) =~ s/^ $package :://x;

  my $indie = "    exit: ";
  my $output  = $indie . $just_sub;
  $output .= "  with $msg" if $msg;
  print STDERR "$output\n" if $debug;;
}




=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
31 May 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
