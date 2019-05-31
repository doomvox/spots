package Spots::HomePage;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::HomePage - generating a page of bookmarks from spots db

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';   # TODO revise before shipping
my $DEBUG = 1; 

=head1 SYNOPSIS

   use Spots::HomePage;

   my $obj = Spots::HomePage->new(
                                   output_basename  => $base,
                                   output_directory => $output_directory,
                                   db_database_name => 'spots_test',
                                  );

   $obj->generate_layout;
   $obj->html_css_from_layout;


=head1 DESCRIPTION

Spots::HomePage provides routines that work with a database of
link urls to generate an html5 page to display them in a tight,
abbreviated form for use in browser homepages.

=head2 terminology

=over 

=item cat 

Links are clustered together into "categories", displayed as small, floating 
"rectangular paragraphs" or "rectparas".  These are most often abbrebiated 
as "cat".

=back 

=head1 METHODS

=over

=cut

use 5.10.0;
# use feature "switch";
no warnings 'experimental';
use Carp;
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use Fatal           qw( open close mkpath copy move );
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::Util      qw( shuffle );
use List::MoreUtils qw( any );
use File::Spec;     # abs2rel

use DBI;

use Spots::Rectangle;

=item new

Creates a new Spots::HomePage object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. Some of these attributes are:

=over

=item output_basename  

The name (sans extension) of the output html and css files                                   

=item output_directory

The location the html and css files will be written

=item html_file  

Name (with path) of output html file, to override the above
output_* settings.

=item css_file

Name (with path) of output css file, to override the output_*
settings.

=item db_database_name 

The db DATABASE name: either 'spots' (the default) or 'spots_test'

=item cats_per_row

Roughly, the number of columns of category rectangles used by
some layout styles.

=item color_scheme

Either 'live' or 'dev'.  The 'live' scheme is light on black. 
The 'dev' scheme has brightly colored boxes to see where things are easily.

=item layout_style

Default is the (usually) the latest, as of this writing: 'metacats_doublezig'.
For others, see L<generate_layout>.  Under development: 'metacats_fanout'

=back

=cut

{ no warnings 'once'; $DB::single = 1; }

has debug => (is => 'rw', isa => Bool, default => sub{return ($DEBUG||0)});

has db_database_name => (is => 'rw', isa => Str, default => 'spots' );

# GENHTML
has output_basename  => (is => 'rw', isa => Str,
                         default => 'moz_ohm' );
# GENHTML
has output_directory => (is => 'rw', isa => Str,
                         default => "$HOME/End/Cave/Spots/Wall" );

has top_bound   => (is => 'ro', isa => Num, default => 0 );
has left_bound  => (is => 'ro', isa => Num, default => 0 );
has bot_bound   => (is => 'ro', isa => Num, default => 10000 );  # big numbers for now
has right_bound => (is => 'ro', isa => Num, default => 10000 );

# default values empirically determined
# rem per line
# has vertical_scale     => (is => 'rw', isa => Num,  default => 1.5 );  
 has vertical_scale     => (is => 'rw', isa => Num,  default => 1.3 );  
# has vertical_scale     => (is => 'rw', isa => Num,  default => 1.17 );  
# has vertical_scale     => (is => 'rw', isa => Num,  default => 1.2 );  
# px per char
# has horizontal_scale   => (is => 'rw', isa => Num,  default => 15    );  
# has horizontal_scale   => (is => 'rw', isa => Num,  default => 9    );  
has horizontal_scale   => (is => 'rw', isa => Num,  default => 12    );  

# has vertical_padding   => (is => 'rw', isa => Num,  default => 0.6 );  # rem
has vertical_padding   => (is => 'rw', isa => Num,  default => 2 );  # rem
# has horizontal_padding => (is => 'rw', isa => Int,  default => 2   );  # px 
has horizontal_padding => (is => 'rw', isa => Int,  default => 10   );  # px 

# used by metacats_fanout, find_hole_for_cat_thataway
has nudge_x => (is => 'rw', isa => Num,  default => 1.5 );  # rem
has nudge_y => (is => 'rw', isa => Int,  default => 6   );  # px 

has initial_y          => (is => 'rw', isa => Int,  default => 0    ); # rem 
has initial_x          => (is => 'rw', isa => Int,  default => 5    ); # px

# GENHTML
has html_file        => (is => 'rw', isa => Str, lazy => 1,
                         builder => 'builder_html_file' );

# GENHTML
has css_file         => (is => 'rw', isa => Str, lazy => 1,
                         builder => 'builder_css_file' );
 
# horizontal distance in px between category "rectpara"s (metacats_doublezig)
has x_gutter       => (is => 'rw', isa => Int, default=>4 );
has y_gutter       => (is => 'rw', isa => Int, default=>1 ); # 1 rem
has cats_per_row   => (is => 'rw', isa => Int, default=>7 );

# has color_scheme => (is => 'rw', isa => Str, default => 'live' ); # or 'dev'
has color_scheme => (is => 'rw', isa => Str, default => 'dev' ); 

has layout_style => (is => 'rw', isa => Str, default => 'metacats_doublezig' ); 

# array of rectangles added to the current layout (used by 'metacats_fanout')
has placed       => (is => 'rw', isa => ArrayRef, default => sub{ [] } );

has dbh              => (is => 'rw',   
                         isa => InstanceOf['DBI::db'],
                         lazy => 1, builder => 'builder_db_connection' );

# CAT -- flagging things to go in new Category.pm (might remove from here, eventually)
has sth_cat           => (is => 'rw',   
                          isa => sub {
                            die "$_[0] not a db statement handle"
                              unless ref $_[0] eq 'DBI::st'
                            },
                          lazy => 1, builder => 'builder_prep_sth_sql_cat');

# CAT
# GENHTML -- reads from layout
has sth_cat_size      => (is => 'rw', 
                          isa => sub {
                            die "$_[0] not a db statement handle"
                              unless ref $_[0] eq 'DBI::st'
                            },
                          lazy => 1,
                          builder => 'builder_prep_sth_sql_cat_size');


# GENHTML
sub builder_html_file {
  my $self = shift;
  my $dir  = $self->output_directory;

  my $base = $self->output_basename;
  my $html_file = "$dir/$base.html";
  return $html_file;
}

# GENHTML
sub builder_css_file {
  my $self = shift;
  my $dir  = $self->output_directory;
  my $base = $self->output_basename;
  my $css_file = "$dir/$base.css";
  return $css_file;
}

# GENHTML -- but not in use
sub builder_html_fh {
  my $self = shift;
  my $html_file = $self->html_file;
  open( my $html_fh, '>', $html_file ); 
  return $html_fh;
}

# GENHTML -- but not in use
sub builder_css_fh {
  my $self = shift;
  my $css_file = $self->css_file;
  open( my $css_fh, '>', $css_file ); 
  return $css_fh;
}

=item builder_db_connection

=cut

sub builder_db_connection {
  my $self = shift;

  # TODO break-out more of these params as object fields
  # TODO add a secrets file to pull auth info from
  my $dbname = $self->db_database_name; # default 'spots'
  # my $port = '5434'; # non-standard port for old build on tango
  my $port = '5432';
  my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
  my $username = 'doom';
  my $auth = '';
  my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
  my $dbh = DBI->connect($data_source, $username, $auth, \%attr);

  return $dbh;
}

=item builder_prep_sth_sql_cat

=cut

# CAT
sub builder_prep_sth_sql_cat {
  my $self = shift;
  my $dbh = $self->dbh;
  my $sql_cat = $self->sql_for_cat();
  my $sth_cat = $dbh->prepare( $sql_cat );
  return $sth_cat;
}

=item builder_prep_sth_sql_cat_size

=cut

# CAT
# GENHTML -- reads the layout
sub builder_prep_sth_sql_cat_size {
  my $self = shift;
  my $dbh = $self->dbh;
  my $sql_cat_size = $self->sql_for_cat_size();
  my $sth_cat_size = $dbh->prepare( $sql_cat_size );
  return $sth_cat_size;
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



=item cat_size_to_layout

Given a ref to an array of cats (i.e. an array of hrefs with keys
cat_id and cat_name); determine the height (in rem) and width (in
px) of each cat, and write to the layout table.

=cut

sub cat_size_to_layout {
  my $self = shift;
  my $cats = shift || $self->list_all_cats(); 
  my $cat_count = scalar( @{ $cats } );
  # $self->hello_sub("cat_count: $cat_count");

  my $popcat = 0; # count of populated cats, i.e. ones with spots
 CAT:
  foreach my $cat ( @{ $cats } ) { 
    my $cat_id   = $cat->{ id };
    # my $cat_name = $cat->{ name };
    my ($cat_spots, $height_in_lines) = $self->lookup_cat( $cat_id );  
    next CAT if not $cat_spots; # skip empty category
    $popcat++;
    my $width_chars = $self->cat_width( $cat_spots );
    my ($height_rem, $width_px) =
      $self->cat_dimensions( $height_in_lines, $width_chars );
    $self->update_height_width_of_cat( $cat_id, $width_px, $height_rem );
  }

  if( $popcat < $cat_count ) {
    my $empties = $cat_count - $popcat;
    warn "There are $empties cats without spots.";
  }
  
  # $self->farewell();
  return $popcat;
}

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

  # general setup
  # moving here, despite redundant 'list_all_cats'  TODO cache cats in object
  my $cats = $self->list_all_cats( $style ); 
  $self->cat_size_to_layout( $cats );  # populate h & w fields

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
  my $cats = shift || $self->list_all_cats(); 
  my $cat_count = scalar( @{ $cats } );
  $self->hello_sub("cat_count: $cat_count");

  unless( $cat_count > 0 ) {
    croak "Sadly, we have no cats, we can not 'generate_layout_metacats_fanout'";
  }

  # initialize $placed array: place the first cat in upper-left
  $self->clear_placed;
  my $placed = $self->placed;
  my ($x1, $y1) = ($self->initial_x, $self->initial_y);
  my $cat = shift @{ $cats };  
  $self->put_cat_in_place( $cat, $x1, $y1 );
 CAT:
  foreach my $cat ( @{ $cats } ) { 
    my $cat_spots = $self->count_cat_spots( $cat ); # implicit fill_in_cat
    next CAT if not $cat_spots; # skip empty category

    my ($x1, $y1) = $self->find_place_for_cat( $cat );
    $self->put_cat_in_place( $cat, $x1, $y1 );
  }
  my $place_count = scalar( @{ $placed } );
  if ($DEBUG) {
    say STDERR "!!! count of placed: $place_count\n";
    $self->placed_summary( $placed );
  }

  $self->check_placed( $placed );

  $self->farewell();
  return $place_count; 
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
  my $placed_count = scalar(@{$placed});
  $self->hello_sub("placed count: " . $placed_count );

  # print STDERR "placed: ", Dumper( $placed ) if $placed_count < 10; ### DEBUG
  # print $self->placed_summary( $placed ) if $placed_count < 10; ### DEBUG

  #  newly choosen x, y vals added to the $cat
  ( $cat->{x}, $cat->{y} ) = ($x1, $y1);

  my ($width, $height) = $self->cat_width_height( $cat ); # implicit fill_in_cat
  my $rect = 
    $self->create_rectangle( $x1, $y1, $width, $height );

  # stash cat stuff in meta info for the rectangle
  my $rect_meta_info = $rect->meta;
  $rect_meta_info->{cat}          = $cat->{id};
  $rect_meta_info->{metacat}      = $cat->{metacat};
  $rect_meta_info->{cat_name}     = $cat->{name};
  $rect_meta_info->{metacat_name} = $cat->{mc_name};

  push @{ $placed }, $rect;
  my $cat_id = $cat->{ id };
  my $ret = 
    $self->update_x_y_of_cat( $cat_id, $x1, $y1 );  # save x,y values to database
  $self->farewell();
  return $ret;
}

=item count_cat_spots

Given a $cat href, returns the count of spots in the category, 
running "fill_in_cat" on it first, if necessary.

Example use:

   my $cat_spots = $self->count_cat_spots( $cat );

=cut

sub count_cat_spots {
  my $self = shift;
  my $cat  = shift;
  my $spot_count;
  no warnings 'uninitialized';
  unless ( defined( $cat->{ spot_count } ) ) {
    $spot_count = $self->fill_in_cat( $cat );   # add data to the $cat    
  }
  $spot_count = $cat->{spot_count};
  return $spot_count
}

=item cat_width_height

Given a $cat href, returns the width and height, running
"fill_in_cat" on it first if necessary.  

Example use:

   my ($width, $height) = $self->cat_width_height( $cat );

=cut

sub cat_width_height {
  my $self = shift;
  my $cat  = shift;
  no warnings 'uninitialized';
  unless ( defined( $cat->{ width } ) && defined( $cat->{ height } ) ) {
    $self->fill_in_cat( $cat );   # add data to the $cat    
  }
  my ($width, $height) = ($cat->{width}, $cat->{height});  
  confess( "cat_width_height: fill_in_cat failed to supply height and width" )
    unless (defined( $width ) && defined( $height ));
  return ($width, $height);
}

=item create_rectangle

Returns a rectangle object at the given point, with given width and height.

Example use:

  my $first_rect = 
    $self->create_rectangle( $x1, $y1, $width, $height );

=cut

sub create_rectangle {
  my $self = shift;
  my $x1 = shift;
  my $y1 = shift;
  my $width = shift;
  my $height = shift;

  confess("create_rectangle: need x1 and y1") unless ( defined( $x1 ) && defined( $y1 ) );
  confess("create_rectangle: height and width must be non-zero") unless ($height>0 && $width>0) ;

  my $x2 = $x1 + $width;
  my $y2 = $y1 + $height;
  my $rect = Spots::Rectangle->new({ coords => [ $x1, $y1, $x2, $y2 ] });  
  return $rect;
}



=item create_rectangle_from_cat

Given a $cat and an x1/y1 point, returns a new rectangle object
for it.  If need be fill_in_cat is called to get height and width.

  my $rect = 
    $self->create_rectangle_from_cat( $cat, $x1, $y1  );

=cut

sub create_rectangle_from_cat {
  my $self = shift;
  my $cat = shift;
  my $x1 = shift;
  my $y1 = shift;
  my ($width, $height) = $self->cat_width_height( $cat );

  my $x2 = sprintf( "%.f",  ($x1 + $width ))    + 0;  # played with forcing numeric: no effect
  my $y2 = sprintf( "%.f",  ($y1 + $height ))   + 0;

#    my $x2 = int( $x1 + $width );
#    my $y2 = int( $y1 + $height );

  my $rect = Spots::Rectangle->new({ coords => [ $x1, $y1, $x2, $y2 ] });  
  return $rect;
}

=item find_place_for_cat

pick location for cat, avoid collision with anything in placed.
also stash cat in "placed" data structure

Example usage:

      my ($x1, $y1) = $self->find_place_for_cat( $cat )

=cut

# STYLE: metacats_fanout
# find a place to put the given cat in the layout
sub find_place_for_cat {
  my $self       = shift;
  my $cat        = shift;
  my $placed     = shift || $self->placed;  # aref of rectangles
  my $cat_name = $cat->{ name };
  my $mc_id    = $cat->{ metacat };
  $self->hello_sub("cat: " . $cat->{id} . ' ' . $cat_name);

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
  $self->candidate_dumper( $candidate_locations );

  # STUBS 

  # my $evaluation_method = "RANDOM";
  # my $evaluation_method = "FIRST_ONE";
  # my $evaluation_method = "THREE_TWO_ONE";
  # my $evaluation_method = "THREE_CYCLE";
  my $evaluation_method = "LAST_ONE";
  state $i;  # my first use of "state"
  my $coords;
  given($evaluation_method) {
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

  my ( $x1, $y1 ) = @{ $coords } if $coords;

  $self->farewell();
  return ( $x1, $y1 );
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

      if( ($a_id == 13 && $b_id == 15) || ($a_id == 15 && $b_id == 13) ) {
        say STDERR "MEEPSTER: i: $i j: $j";  ### i: 3 j: 5
        # say "$a_id: ", Dumper( $a );
        # say "$b_id: ", Dumper( $b );
      }

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

#   my $r1 = $placed->[ 3 ];
#   my $r2 = $placed->[ 5 ]; 
#   say STDERR "Yes, we have overlappage detected" if $r1->is_overlapping( $r2 );
#   say STDERR "Yes, we have overlappage detected" if $r2->is_overlapping( $r1 );
#   $self->placed_summary( [ $r1, $r2 ] );
#   say STDERR Dumper( $r1->coords );
#   say STDERR Dumper( $r2->coords );

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
  $self->hello_sub("looking for place for cat: " . $cat->{id} . ' ' . $cat->{name});

  my ($width, $height) = ($cat->{width}, $cat->{height});

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
  my $cat       = shift;  # a big href, not some sort of object
  my $x_trial   = shift;
  my $y_trial   = shift; 
  my $placed    = shift || $self->placed;
  $self->hello_sub("Looking in direction: $direction to find hole for cat: " . $cat->{id} . ' ' . $cat->{name});

#   # DEBUG
# #  if( $cat->{ id } == 8 && $direction eq 'e' ) {
#   if( $cat->{ id } == 8 ) {
#     say STDERR "Looking in direction: $direction, trying to place cat:";
#     $self->meow( $cat );
#     $self->placed_summary( $placed );
#   }

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
  my $cat_rect = $self->create_rectangle_from_cat( $cat, $x, $y  );
 GAUNTLET: {
      foreach my $placed_rect ( @{ $placed } ) { 
        if ( $cat_rect->is_overlapping( $placed_rect ) ) {  
          # step around overlapped rectangle, try again
          ($x, $y) =
            $self->step_passed_rectangle( $x, $y, $direction, $placed_rect, $cat_rect );
          return undef if $self->position_out_of_bounds( $x, $y );
          $cat_rect = $self->create_rectangle_from_cat( $cat, $x, $y ); # new rect to run gauntlet
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

  my ($new_x, $new_y) = step_passed_rectangle( $x, $y, $direction, $rect );

=cut

sub step_passed_rectangle {
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $direction = shift;
  my $rect = shift;  # move passed this one
  my $fit_rect = shift;  # but need room to squeeze in this one.

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



=item too_close_to_edge

Once we skip passed a placed rectangle, the x,y value may be within bounds, but if the cat 
can't possibly fit there, we might as well bail.

(TODO But then, that might not be my real problem, and this could be a silly thing to check.
      more likely the trouble is that I'm going to check, collide with the same rectangle, then 
      end up getting kicked to the same position where it's going to collide again.)

(Maybe: when crawling north -- and probably west -- I'm stepping far enough: 
 don't just go past the edge of the overlapping rect, also add the height or width of the 
 rect.  That sounds right ish... so fook this for now.  DELME.)

Example usage:

  return undef if $self->too_close_to_edge( $x, $y, $direction, $cat ); # cat has height and width

=cut

# TODO status: not completed, not in use
sub too_close_to_edge {
  my $self = shift;
  my $x = shift;
  my $y = shift;
  my $direction = shift;
  my $cat = shift;
  $self->hello_sub("checking point ($x, $y) in direction: $direction for given cat");

  my $width  = $cat->{width};
  my $height = $cat->{height};

  my $top_bound   = $self->top_bound || 0;
  my $left_bound  = $self->left_bound || 0; 
  my $bot_bound   = $self->bot_bound;
  my $right_bound = $self->right_bound;

  if ( $direction eq 'e' ) { 
#    $x = $rect->x2 + $nudge_x;
  } elsif ( $direction eq 'w' ) {
#    $x = $rect->x1 - $nudge_x;
  } elsif ( $direction eq 's' ) {
#    $y = $rect->y2 + $nudge_y;
  } elsif ( $direction eq 'n' ) {
#    $y = $rect->y1 - $nudge_y;
  } else {
    croak "direction needs to be one of 'e', 'w', 's', or 'n'";
  }



  my $tooclose;
  if( ( $x < $left_bound || $x > $right_bound ) ||
      ( $y < $top_bound  || $y > $bot_bound )      
    ) {
    $tooclose = 1;
  } else {
    $tooclose = 0;
  }
  $self->farewell("tooclose?: $tooclose");
  return $tooclose;
}




=item generate_layout_metacats_doublezig 

=cut

sub generate_layout_metacats_doublezig {
  my $self = shift;
  my ($x, $y) = ($self->initial_x, $self->initial_y);
  # $self->hello_sub("");

  my $cats = $self->list_all_cats('metacats_doublezig'); 

  # moved up to generate_layout
  #  $self->cat_size_to_layout( $cats );  # populate h & w fields

  while ( $cats && scalar( @{ $cats } ) ) { 
    my ( $row_layout, $max_y, $new_x ) =
      $self->generate_layout_for_row( $cats, $x, $y );  # trims $cats as they're used
    foreach my $cat_loc ( @{ $row_layout } ) {
        my ($cat_id, $x, $y, $width_px, $height_rem) = @{ $cat_loc }; 
        $self->update_layout_for_cat( $cat_id, $x, $y, $width_px, $height_rem ); 
    }
    $x = $self->initial_x;           # px 
    $y = $max_y + $self->y_gutter;   # rem
  #    say STDERR  "x: $x, y: $y"
  }
  # $self->farewell();
}

=item generate_layout_for_row

Arranges a chunk of the available sequence of cats in a row of a
height determined by surveying the upcoming cats.  If there's
vertical space in the row for more than one cat (rectangle of
links in a particular category), this routine will frequently
double or triple the cats into a column.  If the next cat exceeds
the allowed veritcal envelope we re-do the process with a new,
larger allowed envelope.

Example usage: 

    my ( $row_layout, $max_y, $final_x ) =
      $self->generate_layout_for_row( $cats, $x, $y );  

Arguments:

  $cats -- array of hashrefs (with main keys id and name).  
           each invocation of this routine shifts the 
           cats off of $cats that have been added to the $row_layout.

  $x --    initial x value for upper-left of row

  $y --    initial y value for upper-left of row


Returns:

  row_layout -- array of *arrays* of cats, fields:
                  cat_id  x  y  width_px  height_rem

  max_y     -- the height of the row in rem

  final_x   -- the width of the row (though unused here)

=cut

sub generate_layout_for_row {
  my $self  = shift;
  my $cats  = shift;
  my $x     = shift;
  my $y     = shift; 
  # $self->hello_sub("cat_count: " . scalar( @{ $cats } ) );
  my $max_y; 

  unless( $cats && scalar( @{ $cats } ) ){
    die "generate_layout_for_row can't do anything without any 'cats'.";
  }

  my $called_with_cats = [];
  @{ $called_with_cats } = @{ $cats } if $cats;  # elephant gun
  my $called_with_y = $y;

  my $x_gutter = $self->x_gutter;
  my $y_gutter = $self->y_gutter;

  my $cats_per_row = $self->cats_per_row;

  # peek ahead at the heights of next chunk of cats
  my $row_height_envelope = 
    $self->max_height_of_next_cats( $cats, $cats_per_row + 1 ); # $cats is aref of hrefs, keys id & name 

  my @row_layout = ();

  my $max_width_px = 0;
  my $col_count = 0;
  my $cpr = $self->cats_per_row;
 COL:
  while( $col_count <= $cpr ) {  # TODO better to use a width in px condition?
    my $bottom = $y;

    # handle the first cat in column
    my ($cat, $cat_id, $cat_name, $cat_spots, $height_rem, $width_px) =
      $self->next_cat( $cats );

    last COL unless $cat_id;

    $max_y = $row_height_envelope + $bottom;  # absolute distance from edge
    if( $height_rem > $max_y ) {
      # increase vertical envelope and reset everything to re-do entire row
      $max_y = $height_rem;
      @row_layout = ();
      @{ $cats } =  @{ $called_with_cats };
      $col_count = 0;
      next COL;
    } else {
      push @row_layout, 
        [$cat_id, $x, $y, $width_px, $height_rem];

      $bottom = $y + $height_rem;
      $y = $bottom + $y_gutter; 
    }

    # max width of cat rectangles in this column
    my $max_width_px = $width_px;

    # add cats below that one, stop just before we exceed the row height
  CAT:
    while ( $bottom <= $max_y ) {
      my ($cat, $cat_id, $cat_name, $cat_spots, $height_rem, $width_px) =
        $self->next_cat( $cats );

      last CAT unless $cat_id;  

      if( ($bottom + $height_rem) <= $max_y ) {
        push @row_layout, 
          [$cat_id, $x, $y, $width_px, $height_rem];
        $bottom = $y + $height_rem;
        $y = $bottom + $y_gutter; 
      } else {
        unshift( @{ $cats }, $cat ); # put the unused cat back
        last CAT;
      }
      if ($width_px > $max_width_px) {
        $max_width_px = $width_px;
      }
    }

    $col_count++;
    # reset $y 
    $y = $called_with_y;
    # advance x for next col of cats
    $x += $max_width_px + $x_gutter;
  }
  # $self->farewell("\n========");
  return ( \@row_layout, $max_y, $x );
}



=item next_cat

Given a ref to an array of cats (i.e. an array of hrefs with keys
cat_id and cat_name), shift off the next cat and return a list of:

  cat        (href)
  cat_id
  cat_name 
  cat_spots  (aref of spots)
  height_rem 
  width_px

Example usage:

 my ($cat_id, $cat_name, $cat_spots, $height_rem, $width_px) =
     $self->next_cat( $cats );

=cut

sub next_cat {
  my $self = shift;
  my $cats = shift;
  # $self->hello_sub("cat_count: " . scalar( @{ $cats } ) );
  my ( $cat, $cat_id, $cat_name, $cat_spots, $height_in_lines );
  do{{
    $cat = shift @{ $cats }; 
    $cat_id   = $cat->{ id };
    $cat_name = $cat->{ name };
    ($cat_spots, $height_in_lines) = $self->lookup_cat( $cat_id );  
  }} until $cat_spots;      # skip empty category

  my $width_chars = $self->cat_width( $cat_spots );

  my ($height_rem, $width_px) =
    $self->cat_dimensions( $height_in_lines, $width_chars );
  # $self->farewell();
  return( $cat, $cat_id, $cat_name, $cat_spots, $height_rem, $width_px );
}




=item cat_width

Example usage:

    my $width_in_chars = $self->cat_width( $cat_spots );

=cut

# CAT
sub cat_width {
  my $self = shift;
  my $cat_spots = shift;

  my $max_chars = 0;
  # for each link line in a cat rectpara
  foreach my $spot ( @{ $cat_spots } ) {
    my $url     =  $spot->{ url };
    my $label   =  $spot->{ label };
    my $spot_id =  $spot->{ id };

    my $chars = length( $label );
    if ( $chars > $max_chars ) {
      $max_chars = $chars;
    }
  }
  return $max_chars;
}





=item max_height_of_next_cats

Look ahead at the next "cats", and return the largest in 
vertical size, in rems.

Example usage:

  my $cat_row_height_rem =
    $self->max_height_of_next_cats( $all_cats, 8 );

=cut

sub max_height_of_next_cats {
  my $self = shift;
  my $cats = shift;
  # $self->hello_sub("cat_count: " . scalar( @{ $cats } ) );
  # get initial size-envelope from upcoming cats
  my $cat_row_height = 0;  # number of lines

  my $horizon = 7;
  if( $#{ $cats } < $horizon ) {
    $horizon = $#{ $cats };
  }

  for( my $i=0; $i<$horizon; $i++ ) { 
    my $cat = $cats->[$i];
    my $cat_id = $cat->{ id };
    my ($cat_spots, $spot_count) = $self->lookup_cat( $cat_id ); 
    if( $spot_count > $cat_row_height ) {
      $cat_row_height = $spot_count;
    }
  }
  my $cat_row_height_rem = 
    ( $self->cat_dimensions($cat_row_height, 1) )[0];
  # $self->farewell();
  return $cat_row_height_rem;
}


=item generate_layout_metacats 

=cut

sub generate_layout_metacats {
  my $self = shift;
  my ($x, $y) = (5, 0);
  my $cats_per_row = $self->cats_per_row;

  my $all_cats = $self->list_all_cats('metacats'); 
  my ($cat_count, $max_h) = (0, 0);
  # for each category rectpara
 CAT: 
  foreach my $cat ( @{ $all_cats } ) {
    my $cat_id   = $cat->{ id };
    my $cat_name = $cat->{ name };

    my ($cat_spots, $spot_count) = $self->lookup_cat( $cat_id );  
    next CAT unless $cat_spots;  # skip empty category

    my $max_chars = 0;
    # for each link line in a cat rectpara
    foreach my $spot ( @{ $cat_spots } ) {
      my $url     =  $spot->{ url };
      my $label   =  $spot->{ label };
      my $spot_id =  $spot->{ id };

      my $chars = length( $label );
      if ( $chars > $max_chars ) {
        $max_chars = $chars;
      }
    }

    my ($height_rem, $width_px) =
      $self->cat_dimensions($spot_count, $max_chars);

    $self->update_layout_for_cat( $cat_id, $x, $y, $width_px, $height_rem );

    my $x_gutter = $self->x_gutter;
    $x += $width_px + $x_gutter;

    if ( $height_rem > $max_h ) {
      $max_h = $height_rem;
    }

    $cat_count++;
    if ( $cat_count > $cats_per_row ) {
      $cat_count = 0;
      $x = 5;
      # note $max_h;
      say STDERR $max_h;
      $y += $max_h + 1;
      $max_h = 0;
    }
  }
}



=item cat_dimensions

Given number of lines and maximum number of characters for a
"cat" (category), get the absolute dimensions to use for a
containing rectangle in rem and px.

Example usage: 

    my ($height_rem, $width_px) = 
      $self->cat_dimensions( $spot_count, $max_chars );

=cut

sub cat_dimensions {
  my $self = shift;
  my $spot_count = shift;
  my $max_chars  = shift;

  my $vertical_scale     = $self->vertical_scale;     # 1.20 rem per line 
  my $vertical_padding   = $self->vertical_padding;   #   maybe 0.5 rem 
  my $horizontal_scale   = $self->horizontal_scale;   # 9 px per char 
  my $horizontal_padding = $self->horizontal_padding; #   maybe 2 pxb

  my $height_raw =   $spot_count * $vertical_scale   + $vertical_padding;
  my $height = sprintf( "%.1f", $height_raw );
#  my $width  = int( $max_chars  * $horizontal_scale + $horizontal_padding ); 
  my $width  = sprintf( "%.0d", ( $max_chars  * $horizontal_scale + $horizontal_padding )); 
#  my $width  = sprintf( "%.f", ( $max_chars  * $horizontal_scale + $horizontal_padding )); 
  return ($height, $width);
}




=item generate_layout_by_size

=cut

sub generate_layout_by_size {
  my $self = shift;
  my ($x, $y) = (5, 0);
  my $cats_per_row = $self->cats_per_row;

  my $all_cats = $self->list_all_cats('by_size'); 

  my ($cat_count, $max_h) = (0, 0);
  # for each category rectpara
 CAT: 
  foreach my $cat ( @{ $all_cats } ) {
    my $cat_id   = $cat->{ id };
    my $cat_name = $cat->{ name };

    my ($cat_spots, $spot_count) = $self->lookup_cat( $cat_id );  
    next CAT unless $cat_spots;  # skip empty category

    my $max_chars = 0;
    # for each link line in a cat rectpara
    foreach my $spot ( @{ $cat_spots } ) {
      my $url     =  $spot->{ url };
      my $label   =  $spot->{ label };
      my $spot_id =  $spot->{ id };

      my $chars = length( $label );
      if ( $chars > $max_chars ) {
        $max_chars = $chars;
      }
    }

    my $vertical_scale   = $self->vertical_scale;    # 1.20 rem per line
    my $horizontal_scale = $self->horizontal_scale;  # 9 px per char
    
    my $height =  sprintf "%.1f", ($spot_count * $vertical_scale) ; # height for lines (rem)
    my $width  =  sprintf "%.0f", ($max_chars  * $horizontal_scale) ;  # width for chars (px)

    $self->update_layout_for_cat( $cat_id, $x, $y, $width, $height );

    my $x_gutter = $self->x_gutter;
    $x += $width + $x_gutter;

    if ( $height > $max_h ) {
      $max_h = $height;
    }

    $cat_count++;
    if ( $cat_count > $cats_per_row ) {
      $cat_count = 0;
      $x = 5;
      # note $max_h;
      say STDERR $max_h;
      $y += $max_h + 1;
      $max_h = 0;
    }
  }
}


=back 

=head2 output 

=over

=item html_css_from_layout

Generate the html and css files from the coordinates in the layout table.

=cut

# GENHTML -- reads the layout
sub html_css_from_layout {
  my $self = shift;

#  my $cats_per_row = $self->cats_per_row;

  my $html_file = $self->html_file;
  my $css_file  = $self->css_file;

  open( my $html_fh, '>', $html_file ) or die "could not open $html_file: $!";
  open( my $css_fh,  '>', $css_file )  or die "could not open $css_file: $!";

  # Add the headers to both html and css
  my $html_head = $self->html_header();
  my $html_container_head = $self->html_container_head();
  print {$html_fh} $html_head, $html_container_head;

  my ($container_height, $container_width) = 
    $self->maximum_height_and_width_of_layout;

  my $css_head = $self->css_header( $container_height );
  print {$css_fh} $css_head;

  my $all_cats = $self->list_all_cats;
  my ($rp_count, $max_h)  = (0, 0);
  foreach my $c ( @{ $all_cats } ) {
    my $cat_id   = $c->{ id };
    my $cat_name = $c->{ name };

    my ($cat_spots, $spot_count, $x, $y, $w, $h) = 
      $self->lookup_cat_and_size( $cat_id );  

    my $css_cat_id  = "cat" . sprintf("%04d", $cat_id);
    my $cat_html =
      qq{<div class="category" id="$css_cat_id" data-catname="$cat_name" >\n}; 

    my $max_chars = 0;
    foreach my $t ( @{ $cat_spots } ) {
      my $url     =  $t->{ url };
      my $label   =  $t->{ label };
      my $spot_id =  $t->{ id };
      my $link    =  qq{<a href="$url">$label</a>};
      $cat_html .= "$link<br>\n";
    }
    
    $cat_html =~ s{<br>$}{<b>*$cat_id*</b><br>}x; ### DEBUG
    $cat_html .= "$cat_id: $cat_name"; ### DEBUG

    $cat_html .= qq{</div>\n};

    # print block to the html handle
    print {$html_fh} $cat_html, "\n";

    # css for the category                    
    my $x_str = $x . 'px';
    my $y_str = $y . 'rem'; 

    my $w_str  = $w . 'px';  # estimated width to fit number of chars.
    my $h_str  = $h . 'rem'; # height sized for the number of lines

# # TODO this doesn't work (?)
#     my $cat_css =<<"____END_CSS";
#       #$css_cat_id { position: absolute;    
#                      top:  $y_str; 
#                      left: $x_str; 
#                      height: $h_str;        
#                      width:  $w_str;        
#                      margin: 0px;   
#                      padding: 0px;  
#                      border: solid 1px;  
#                      data-catname: $cat_name; };
  
# ____END_CSS

    my $cat_css =
      qq(#$css_cat_id { position: absolute;    ) .
      qq(               top:  $y_str; ) .
      qq(               left: $x_str; ) .
      qq(               height: $h_str;        ) .
      qq(               width:  $w_str;        ) .
      qq(               margin: 0px;  ) .
      qq(               padding: 0px;  ) .
      qq(               border: solid 1px;  ) .
      qq(               data-catname: $cat_name; } );

    print STDERR "cat_css: $cat_css\n" unless $a++;

    # print block to the css handle
    print {$css_fh} $cat_css, "\n";
  }

  # add the footers to both html and css
  my $html_foot = html_footer();
  my $html_container_footer = html_container_footer();
  my $css_foot = css_footer();

  print {$html_fh} $html_container_footer, $html_foot;
  print {$css_fh}  $css_foot;
}

=back 

=head2 db access routines

=over 

=item list_all_cats

Return an array of hrefs keyed like:

  id   => cat id
  name => cat name
  cnt  => link lines per cat

=cut

sub list_all_cats {
  my $self = shift;
#  my $style = shift || 'by_size';
  my $style = shift || $self->layout_style;
  my $dbh = $self->dbh;

  my $sql = $self->sql_for_all_cats( $style );
  my $sth = $dbh->prepare( $sql );
  $sth->execute;
  my $all_cats = $sth->fetchall_arrayref({});
  return $all_cats;
}

=item lookup_cat

Example usage:

   my ($cat_spots, $spot_count) = $self->lookup_cat( $cat_id );  

=cut

sub lookup_cat {
  my $self = shift;
  my $cat_id = shift;
  my $sth_cat      = $self->sth_cat;
  $sth_cat->execute( $cat_id );
  my $cat_spots = $sth_cat->fetchall_arrayref({}); 
  my $spot_count = scalar( @{ $cat_spots } );      
  return( $cat_spots, $spot_count );
}



=item fill_in_cat

Given a $cat (href with field 'cat_id'), gets additional
information about it and adds it to the $cat href:

  width
  height
  x
  y 
  spots       (aref)
  spot_count

Note: the x and y information may not yet be defined.

Essentially, a variation of L<lookup_cat_and_size>.

Example usage:

    my $cat_spots = $self->fill_in_cat( $cat );   # add data to the $cat


=cut

# CAT
sub fill_in_cat {
  my $self = shift;
  my $cat = shift;

  my $sth_cat      = $self->sth_cat;
  my $sth_cat_size = $self->sth_cat_size;  

  my $cat_id = $cat->{ id };
  $sth_cat->execute( $cat_id );
  my $cat_spots = $sth_cat->fetchall_arrayref({});
  my $spot_count = scalar( @{ $cat_spots } ); 

  # pulling x and y from db table layout
  $sth_cat_size->execute( $cat_id );  
  my $cat_size = $sth_cat_size->fetchrow_hashref();
  my $x = $cat_size->{ x_location };
  my $y = $cat_size->{ y_location };
  my $w = $cat_size->{ width };
  my $h = $cat_size->{ height };

  $cat->{ width }  = $w;
  $cat->{ height } = $h;
  $cat->{ x } = $x if $x;
  $cat->{ y } = $y if $y;
  $cat->{ spots } = $cat_spots;
  $cat->{ spot_count } = $spot_count;

  return $spot_count;
}



=item lookup_cat_and_size

Example usage:

    my ($cat_spots, $spot_count, $x, $y, $w, $h) = 
      $self->lookup_cat_and_size( $cat_id );  

=cut

sub lookup_cat_and_size {
  my $self   = shift;
  my $cat_id = shift;

  my $sth_cat      = $self->sth_cat;
  my $sth_cat_size = $self->sth_cat_size;  

  $sth_cat->execute( $cat_id );
  my $cat_spots = $sth_cat->fetchall_arrayref({});
  my $spot_count = scalar( @{ $cat_spots } ); ### RM

  # pulling x and y from db table layout
  $sth_cat_size->execute( $cat_id );  
  my $cat_size = $sth_cat_size->fetchrow_hashref();
  my $x = $cat_size->{ x_location };
  my $y = $cat_size->{ y_location };
  my $w = $cat_size->{ width };
  my $h = $cat_size->{ height };

  return( $cat_spots, $spot_count, $x, $y, $w, $h );  
}



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



=item update_layout_for_cat

Store the layout information for a particular cat.

Example usage:

  $self->update_layout_for_cat( $cat_id, $x, $y, $width, $height );

=cut

sub update_layout_for_cat {
  my $self   = shift;
  my $cat_id = shift;
  my $x      = shift;
  my $y      = shift;
  my $width  = shift;
  my $height = shift;

  $x      = sprintf "%.0f", $x;
  $y      = sprintf "%.0f", $y;
  $width  = sprintf "%.0f", $width;
  $height = sprintf "%.1f", $height;

  my $sql_update =
    $self->sql_to_update_layout( $cat_id, $x, $y, $width, $height );

  my $dbh = $self->dbh;
  my $rows_affected = 
    $dbh->do( $sql_update );
  # $dbh->commit;  # even though AutoCommit is on
  return $rows_affected;
}


=item update_height_width_of_cat

Store the layout information for a particular cat.

Example usage:

  $self->update_height_width_of_cat( $cat_id, $width, $height );

=cut

sub update_height_width_of_cat {
  my $self   = shift;
  my $cat_id = shift;
  my $width  = shift;
  my $height = shift;

  my $sql_update = $self->sql_to_update_height_width();
  # UPDATE layout SET width=?, height=? WHERE category = ?

  my $dbh = $self->dbh;

  my $sth = $dbh->prepare( $sql_update );  # TODO stash prepared sth (maybe)
   $sth->execute( $width, $height, $cat_id ); 
  return;
}

=item update_x_y_of_cat

Store the layout information for a particular cat.

Example usage:

  $self->update_x_y_of_cat( $cat_id, $x, $y );

=cut

sub update_x_y_of_cat {
  my $self   = shift;
  my $cat_id = shift;
  my $x      = shift;
  my $y      = shift;
  $self->hello_sub("cat_id: $cat_id x: $x, y: $y");

  $x      = sprintf "%.0f", $x;
  $y      = sprintf "%.0f", $y;

  my $sql_update = $self->sql_to_update_x_y();
  #     UPDATE layout SET x_location=?, y_location=? WHERE category = ?
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare( $sql_update );  # TODO stash prepared sth (maybe)
  $sth->execute( $x, $y, $cat_id );
  say STDERR "error: ", $sth->errstr if $sth->err;
  $self->farewell();
  return;
}



=item maximum_height_and_width_of_layout

Determine the height (rem) and width (px) of the layout.

Example usage:

  my ($height, $width) = 
    $self->maximum_height_and_width_of_layout;

=cut

# GENHTML
sub maximum_height_and_width_of_layout {
  my $self   = shift;
  my $dbh = $self->dbh;
  my $sql =
    qq{SELECT MAX( x_location  + width ) AS w, } .
    qq{ MAX( y_location  + height ) AS h FROM layout};

  my $sth = $dbh->prepare( $sql );
  $sth->execute;
  my $layout_size = $sth->fetchrow_hashref();
  my $h = $layout_size->{ h };
  my $w = $layout_size->{ w };

  return( $h, $w );
}

=back

=head2 sql 

=over 

=item sql_for_all_cats

SQL to get a listing of all categories and the line count of urls
they contain, sorted in order of biggest to smallest.

=cut

sub sql_for_all_cats {
  my $self = shift;
#  my $style = shift || 'by_size';
  my $style = shift || $self->layout_style;

  # use the same sql for the variant style
  if( $style eq 'metacats_doublezig' || $style eq 'metacats_fanout' ) {
    $style = 'metacats';
  }

  my $sql_all_cats;
  if ($style eq 'by_size') { 
    $sql_all_cats =<<"______END_SKULL_BY_SIZE";
      SELECT 
        category AS id, 
        category.name AS name, 
        COUNT(*) AS cnt 
       FROM category, spots 
       WHERE 
         spots.category = category.id 
       GROUP BY 
         category, 
         category.name 
       ORDER BY COUNT(*) DESC 
______END_SKULL_BY_SIZE
  } elsif( $style eq 'metacats' ) {
    $sql_all_cats =<<"______END_SKULL_METACAT";
      SELECT
        metacat.sortcode  AS mc_ord,
        metacat.name      AS mc_name, 
        metacat.id        AS metacat,
        category.id       AS id,
        category.name     AS name,
        count(*)          AS cnt
      FROM
        metacat, category, spots
      WHERE
        spots.category = category.id AND
        category.metacat = metacat.id 
      GROUP BY 
        metacat.sortcode,
        metacat.name,
        metacat.id,
        category.id,
        category.name
      ORDER BY 
        metacat.sortcode,
        metacat.name,
        metacat.id,
        category.id,
        category.name;
______END_SKULL_METACAT
  } 

  return $sql_all_cats;
}

=item sql_for_cat

SQL to get label and url information for a given category.id.

=cut

sub sql_for_cat {
  my $self = shift;
  my $sql_cat =<<"__END_CAT_SKULL";
    SELECT spots.id AS id, url, label, category.metacat AS metacat
    FROM spots JOIN category ON (category.id = spots.category) 
    WHERE category.id = ?
__END_CAT_SKULL
  return $sql_cat;
}

=item sql_for_cat_size

SQL to get position information for a given category.id.

=cut

# GENHTML -- reads the layout
sub sql_for_cat_size {
  my $self = shift;
  my $sql_pos =
    qq{ SELECT x_location, y_location, width, height FROM layout } .
    qq{ WHERE category = ? };
  return $sql_pos;
}

=item sql_to_update_layout

  my $sql_update = $self->sql_to_update_layout( $x, $y, $cat );

=cut

# TODO Q: why string interpolation rather than bind params?

# TODO doing an upsert would require a uniqueness contraint on category:
# (( which I now have-- Sun  May 26, 2019  12:18  fandango ))

#   my $update_sql = 
#   qq{ INSERT INTO layout (category, x_location, y_location) 
#       VALUES ($cat_id, $x, $y) 
#       ON CONFLICT (category) 
#       DO 
#         UPDATE
#           SET x_location=$x, y_location=$y; };

##  DBD::Pg::db do failed: ERROR:  there is no unique or exclusion constraint matching the ON CONFLICT specification at /home/doom/End/Cave/Spots/Wall/Spots/t/../lib/Spots/HomePage.pm line 867.

sub sql_to_update_layout {
  my $self       = shift;
  my $cat_id     = shift;
  my $x = shift;
  my $y = shift;
  my $width      = shift;
  my $height     = shift;

#   my $update_sql = 
#     qq{UPDATE layout } .
#     qq{SET x_location=$x, y_location=$y, width=$width, height=$height } .
#     qq{   WHERE category = $cat_id };

  my $update_sql = 
  qq{ INSERT INTO layout (category, x_location, y_location) 
      VALUES ($cat_id, $x, $y) 
      ON CONFLICT (category) 
      DO 
        UPDATE
          SET x_location=$x, y_location=$y; };

  return $update_sql;
}

=item sql_to_update_height_width

  my $sql_update = $self->sql_to_update_height_width()

=cut

sub sql_to_update_height_width {
  my $self       = shift;
  my $update_sql =<<"__END_SKULL_UHW";
    UPDATE layout SET width=?, height=? WHERE category = ?
__END_SKULL_UHW
  return $update_sql;
}

=item sql_to_update_x_y

  my $sql_update = $self->sql_to_update_x_y()

=cut

sub sql_to_update_x_y {
  my $self       = shift;
  my $update_sql =<<"__END_SKULL_UHW";
    UPDATE layout SET x_location=?, y_location=? WHERE category = ?
__END_SKULL_UHW
  return $update_sql;
}



=item clear_layout

Blank out the coordinate columns in the layout table:
  x_location, y_location, width, height

Safety feature: this will only work if dname contains string "test".

=cut

sub clear_layout {
  my $self = shift;

  my $dbname = $self->db_database_name;
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



=back

=head2 embedded html/css routines

=over 


=item colors

=cut

# GENHTML
sub colors {
  my $self = shift;
  my $color_scheme = shift || $self->color_scheme;

  my %colors;

  my $black = '#000000';
  
  if ( $color_scheme eq 'dev' ) { 
#     %colors = 
#       (
#        container_bg => '#99AAEE',
#        category_bg  => '#DDFF00',
#        footer_bg    => 'lightgray',
#        anchor_fg    => '#003333',
#        body_bg      => '#000000',
#        body_fg      => '#CC33FF', 
#       );
    %colors = 
      (
       container_bg => '#225588',
       category_bg  => '#BBDD00',
       footer_bg    => 'lightgray',
       anchor_fg    => '#001111',
       body_bg      => '#000000',
       body_fg      => '#CC33FF', 
      );
  } elsif ($color_scheme eq 'live' ) { 
    %colors = 
      (
       container_bg => $black,
       category_bg  => $black,
       footer_bg    => $black,
       anchor_fg    => '#EFFFFF',
       body_bg      => $black,
       body_fg      => $black,
      );
  }

  return \%colors;
}

=item html_header

=cut

# GENHTML
sub html_header {
  my $self = shift;
  my $title = shift;
  my $spiel = shift || '';

  # my $heading = qq{<title>$title</title>};
  my $heading = '';

  my $css_file = $self->css_file || 'mah_moz_ohm.css';
  my $html_file = $self->html_file;
  my $css_rel = File::Spec->abs2rel( $css_file, dirname( $html_file ) );

  my $html = <<"__END_HTML_HEAD";
<!DOCTYPE html>
<html lang="en_US" dir="ltr">
<head>
<meta charset="utf-8">
$heading
<meta name="author" content="Joseph Brenner">
<link rel="stylesheet" type="text/css" href="$css_rel">
</head>

<body>

__END_HTML_HEAD

  $html .= qq{<h2>$title</h2>} if $title;
  $html .= qq{<P>$spiel</P>}   if $spiel;
  return $html;
}


=item css_header

Takes one argument, the vertical height of the container div in rem.

  print $self->css_header( 150 );

=cut

# GENHTML
sub css_header {
  my $self   = shift;
  my $height = shift || 150;
  my $height_str = $height . 'rem';


  my $color_scheme = $self->color_scheme;
  my $colors       = $self->colors( $color_scheme );
  my $container_bg = $colors->{ container_bg };
  my $category_bg  = $colors->{ category_bg };
  my $footer_bg    = $colors->{ footer_bg };
  my $anchor_fg    = $colors->{ anchor_fg };
  my $body_bg      = $colors->{ body_bg };
  my $body_fg      = $colors->{ body_fg };


  my $css = <<"__END_CSS_HEAD";
body { 
  font-family: helvetica, verdana, arial, sans-serif;
}

a {
  color:      $anchor_fg
}

body {
  color:      $body_fg;
  background: $body_bg;
  box-sizing: border-box:
}

.container {
    position: relative;
    top:  2px;
    left: 30px;
    background: $container_bg;
    border: dotted;
    height: $height_str;
}

.footsie {
    max-width: 400px;
    background: $footer_bg;
}

.category {
       background: $category_bg;
       border: solid 1px;
       padding: 2px;
       position: absolute;
}

__END_CSS_HEAD
  return $css;
}

=item html_footer

=cut

# GENHTML
sub html_footer {
  my $self = shift;

  my $timestamp = localtime();
  my $email = "mailto:doom\@kzsu.stanford.edu";
  my $author = "Joseph Brenner";

  my $html = <<"__END_HTML_FOOT";
<hr>
<DIV class="footsie">
<address>
<a href="$email">$author</a>,
$timestamp
</address>
</DIV>
</body>
</html>
__END_HTML_FOOT
  return $html;
}


=item css_footer

=cut

# GENHTML
sub css_footer {
  my $self = shift;
  my $arg = shift;
  my $css = <<"__END_CSS_FOOT";
__END_CSS_FOOT
  return $css;
}



=item html_container_head

=cut

# GENHTML
sub html_container_head {
  my $self = shift;
  my $arg = shift;

#   my $html = <<"__END_CONTAINER_HEAD";
#   <div class="container">
# __END_CONTAINER_HEAD

  my $html = qq{<div class="container">};
  return $html;
}

=item html_container_footer

=cut

# GENHTML
sub html_container_footer {
  my $self = shift;
  my $arg = shift;
#   my $html = <<"__END_CONTAINER_FOOT";
#   </div> <!-- end container -->
# __END_CONTAINER_FOOT

  my $html = qq{</div> <!-- end container -->};

  return $html;
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


=item dbg

Output message to STDERR, but only if debug is on.

=cut

sub dbg {
  my $self = shift;
  my $msg     = shift;  # describing/sampling args 

  my $debug = $DEBUG || $self->debug;

  my $package = ( caller(1) )[0];
  my $sub     = ( caller(1) )[3];
  (my $just_sub = $sub) =~ s/^ $package :://x;
  ### Get line number?  Or getting too carpy?

  my $output  = "$just_sub: $msg";
  $output .= " with $msg" if $msg;

  print STDERR "$output\n" if $debug;
}




=item placed_summary

Dumps a summary of an array of href-based objects to STDERR.
Examines x1, y1, x2, y2, meta/cat, meta/cat_name, meta/metacat

Also reports width=x2-x1, height=y2-y1.

=cut

sub placed_summary {
  my $self = shift;
  my $placed = shift || $self->placed;

  my $count = scalar(@{ $placed });
  my $class = ref( $placed->[0] );

#  print STDERR "$count objects of $class\n";
  my $report = "$count objects of $class\n";
  foreach my $p ( @{ $placed } ) {
#    my ($x1, $y1, $x2, $y2, $meta) = @{ $p }{ 'x1', 'y1', 'x2', 'y2', 'meta' };
    my ($x1, $y1, $x2, $y2, $meta) = ( $p->x1, $p->y1, $p->x2, $p->y2, $p->meta );
    my ($cat, $cat_name, $metacat) = @{ $meta }{ 'cat', 'cat_name', 'metacat' };
    my ($width, $height) = ( $x2-$x1, $y2-$y1 );
#     print STDERR "  $cat: $cat_name\t$metacat";
#     print STDERR "  [ $x1, $y1 ]\t[ $x2, $y2 ]\t" . $width . 'x' . $height. "\n";
    my $fmt = 
      qq{%4d: %-10s mc:%-4d [%6.1f,%6.1f]  [%6.1f,%6.1f]  %6.1f x %-6.1f \n};
    $report .= sprintf $fmt, 
      $cat, $cat_name, $metacat, $x1, $y1, $x2, $y2, $width, $height;
  }
  print STDERR $report;
  return $report;
}

=item candidate_dumper

Dumps a list of an array of arefs to stderr in 
a tighter format than Data:Dumper (which isn't hard).

=cut

sub candidate_dumper {
  my $self = shift;
  my $candidates = shift;
  my $count = scalar(@{ $candidates });

  print STDERR "count of candidates: $count\n";
  print STDERR '$candidates = [', "\n";
  foreach my $pair (@{$candidates}) {
    my ($x, $y) = @{ $pair };
#    print STDERR "  [ $x, $y ]\n";
    my $fmt = "   [%6.1f,%6.1f]\n";
    printf STDERR $fmt, $x, $y;
  }
  print STDERR '];', "\n";
}



=item meow

Report on a cat hashref, reasonably succinctly.

=cut

sub meow {
  my $self = shift;
  my $cat  = shift;

  my $id   = $cat->{id};
  my $name = $cat->{name};

  my $width  = $cat->{width};
  my $height = $cat->{height};

  my $x  = $cat->{x};  
  my $y  = $cat->{y};  
  
  my $spots = $cat->{spots};
  my $spot_count = scalar( @{ $cat->{spots} } );
  
  my $report = qq{ $id $name ($x, $y) $width x $height spots: $spot_count };
  say STDERR $report;
  return $report;
}





=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
25 Mar 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
