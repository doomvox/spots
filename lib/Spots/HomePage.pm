package Spots::HomePage;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::HomePage - generating a page of bookmarks from spots db

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
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
use Carp;
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use Fatal           qw( open close mkpath copy move );
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use List::MoreUtils qw( any );

use DBI;

=item new

Creates a new Spots::HomePage object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=item 

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );

# $DB::single = 1;

has db_database_name => (is => 'rw', isa => Str, default => 'spots' );

has output_basename  => (is => 'rw', isa => Str, default => 'moz_ohm' );
has output_directory => (is => 'rw', isa => Str, default => '/home/doom/End/Cave/Spots/Wall' );

# the values here were empirically determined
has vertical_scale     => (is => 'rw', isa => Num,  default => 1.20 );  # rem per line
has horizontal_scale   => (is => 'rw', isa => Int,  default => 9    );  # px per char

has html_file        => (is => 'rw', isa => Str, lazy => 1, builder => 'builder_html_file' );
has css_file         => (is => 'rw', isa => Str, lazy => 1, builder => 'builder_css_file' );

# TODO why *doesn't* this work?
# has html_fh          => (is => 'rw', isa => sub {
#                            die "$_[0] not a file handle" unless ref $_[0] eq 'GLOB'
#                          },
#                          lazy => 1, builder => 'builder_html_fh' );

# has css_fh          => (is => 'rw', isa => sub {
#                            die "$_[0] not a file handle" unless ref $_[0] eq 'GLOB'
#                          },
#                          lazy => 1, builder => 'builder_css_fh' );


# horizontal distance in px between category "rectpara"s
has gutter          => (is => 'rw', isa => Int, default=>4 );
has cats_per_row    => (is => 'rw', isa => Int, default=>7 );

# The way I'd like Moo to work:
#   has dbh              => (is => 'rw', isa => 'DBI::db',  lazy => 1, builder => 'builder_db_connection' );
# What I'm supposed to do (who would think this is better than Mouse?):
has dbh              => (is => 'rw',   
                         isa => sub {
                           die "$_[0] not a db handle" unless ref $_[0] eq 'DBI::db'
                         },
                         lazy => 1, builder => 'builder_db_connection' );

has sth_cat              => (is => 'rw',   
                             isa => sub {
                               die "$_[0] not a db statement handle" unless ref $_[0] eq 'DBI::st'
                             },
                            lazy => 1, builder => 'builder_prep_sth_sql_cat');


has sth_cat_size          => (is => 'rw', 
                             isa => sub {
                               die "$_[0] not a db statement handle" unless ref $_[0] eq 'DBI::st'
                             },
                            lazy => 1, builder => 'builder_prep_sth_sql_cat_size');


sub builder_html_file {
  my $self = shift;
  my $dir  = $self->output_directory;
  my $base = $self->output_basename;
  my $html_file = "$dir/$base.html";
  return $html_file;
}

sub builder_css_file {
  my $self = shift;
  my $dir  = $self->output_directory;
  my $base = $self->output_basename;
  my $css_file = "$dir/$base.css";
  return $css_file;
}

sub builder_html_fh {
  my $self = shift;
  my $html_file = $self->html_file;
  open( my $html_fh, '>', $html_file ); 
  return $html_fh;
}


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
  my $dbname = $self->db_database_name; # default 'spots'
  my $port = '5434';
  my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
  my $username = 'doom';
  my $auth = '';
  my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
  my $dbh = DBI->connect($data_source, $username, $auth, \%attr);

  return $dbh;
}


=item builder_prep_sth_sql_cat

=cut

sub builder_prep_sth_sql_cat {
  my $self = shift;
  my $dbh = $self->dbh;
  my $sql_cat = $self->sql_for_cat();
  my $sth_cat = $dbh->prepare( $sql_cat );
  return $sth_cat;
}

=item builder_prep_sth_sql_cat_size

=cut

sub builder_prep_sth_sql_cat_size {
  my $self = shift;
  my $dbh = $self->dbh;
  my $sql_cat_size = $self->sql_for_cat_size();
  my $sth_cat_size = $dbh->prepare( $sql_cat_size );
  return $sth_cat_size;
}




=back

=head2 routines to do, like, stuff

=over 

=item generate_layout

Use the spots/categories tables to generate a layout scheme,
saving the coordinates to the layout table.

=cut

sub generate_layout {
  my $self = shift;

  my ($x, $y) = (5, 0);
  my $cats_per_row = $self->cats_per_row;

  my $all_cats = $self->list_all_cats;
  my ($cat_count, $max_h) = (0, 0);
  # for each category rectpara
 CAT: 
  foreach my $cat ( @{ $all_cats } ) {
    my $cat_id   = $cat->{ id };
    my $cat_name = $cat->{ name };

    my ($cat_spots, $spot_count) = $self->lookup_cat( $cat_id );  
    next CAT unless $cat_spots;  # skip empty categories

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
    
    my $height =  $spot_count * $vertical_scale ;    # height sized for the number of lines (rem)
    my $width  =  $max_chars  * $horizontal_scale ;  # estimated width to fit number of chars (px)

    $self->update_layout_for_cat( $cat_id, $x, $y, $width, $height );

    my $gutter = $self->gutter;
    $x += $width + $gutter;

    if ( $height > $max_h ) {
      $max_h = $height;
    }

    $cat_count++;
    if ( $cat_count > $cats_per_row ) {
      $cat_count = 0;
      $x = 5;
      say STDERR $max_h;
      $y += $max_h + 1;
      $max_h = 0;
    }
  }
}



=item html_css_from_layout

Generate the html and css files from the coordinates in the layout table.

=cut

sub html_css_from_layout {
  my $self = shift;

  my $cats_per_row = $self->cats_per_row;

  my $html_file = $self->html_file;
  my $css_file  = $self->css_file;

  open( my $html_fh, '>', $html_file ) or die "could not open $html_file: $!";
  open( my $css_fh,  '>', $css_file )  or die "could not open $css_file: $!";

  # Add the headers to both html and css
  my $html_head = $self->html_header();
  print {$html_fh} $html_head;

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
    my $cat_html = qq{<div class="categories" id="$css_cat_id" data-catname="$cat_name" >\n}; 

    my $max_chars = 0;
    foreach my $t ( @{ $cat_spots } ) {
      my $url     =  $t->{ url };
      my $label   =  $t->{ label };
      my $spot_id =  $t->{ id };
      my $link    =  qq{<a href="$url">$label</a>};
      $cat_html .= "$link<br>\n";
    }

    $cat_html .= qq{</div>\n};

    # print block to the html handle
    print {$html_fh} $cat_html, "\n";

    # css for the categories                    
    my $x_str = $x . 'px';
    my $y_str = $y . 'rem'; 

    my $w_str  = $w . 'px';  # estimated width to fit number of chars.
    my $h_str  = $h . 'rem'; # height sized for the number of lines

    my $cat_css =
      qq(#$css_cat_id { position: absolute;    ) .
      qq(               top:  $y_str; ) .
      qq(               left: $x_str; ) .
      qq(               height: $h_str;        ) .
      qq(               width:  $w_str;        ) .
      qq(               data-catname: $cat_name; } );

    # print block to the css handle
    print {$css_fh} $cat_css, "\n";
  }

  # add the footers to both html and css
  my $html_foot = html_footer();
  my $css_foot = css_footer();

  print {$html_fh} $html_foot;
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
  my $dbh = $self->dbh;

  my $sql = $self->sql_for_all_cats();
  my $sth = $dbh->prepare( $sql );
  $sth->execute;
  my $all_cats = $sth->fetchall_arrayref({});
  return $all_cats;
}

# 


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

  my $sql_update = $self->sql_to_update_layout( $cat_id, $x, $y, $width, $height );

  my $dbh = $self->dbh;
  my $rows_affected = 
    $dbh->do( $sql_update );
  # $dbh->commit;  # even though AutoCommit is on
  return $rows_affected;
}



=item maximum_height_and_width_of_layout

Determine the height (rem) and width (px) of the layout.

Example usage:

  my ($height, $width) = 
    $self->maximum_height_and_width_of_layout;
  
=cut

sub maximum_height_and_width_of_layout {
  my $self   = shift;
  my $dbh = $self->dbh;
  my $sql =
    qq{select max( x_location  + width ) AS w, max( y_location  + height ) AS h from layout};

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

  my $sql_all_cats =
  qq{ SELECT categories AS id, categories.name AS name, COUNT(*) AS cnt 
      FROM spots, categories WHERE spots.categories = categories.id 
      GROUP BY categories, categories.name ORDER BY COUNT(*) DESC };

  return $sql_all_cats;
}

=item sql_for_cat

SQL to get label and url information for a given categories.id.

=cut

sub sql_for_cat {
  my $self = shift;
  my $sql_cat = "SELECT id, url, label FROM spots WHERE categories = ?";
  return $sql_cat;
}

=item sql_for_cat_size

SQL to get position information for a given categories.id.

=cut

sub sql_for_cat_size {
  my $self = shift;
  my $sql_pos = "SELECT x_location, y_location, width, height FROM layout WHERE categories = ?";
  return $sql_pos;
}

=item sql_to_update_layout

  my $sql_update = $self->sql_to_update_layout( $x, $y, $cat );

=cut

# TODO Q: why am I interpolating rather than using bind params?

# TODO do an upsert instead of a simple update?
# 
#   my $update_sql = 
#   qq{ INSERT INTO layout (categories, x_location, y_location) 
#       VALUES ($cat_id, $x, $y) 
#       ON CONFLICT (categories) 
#       DO 
#         UPDATE
#           SET x=$x, y = $y; };

sub sql_to_update_layout {
  my $self       = shift;
  my $cat_id     = shift;
  my $x = shift;
  my $y = shift;
  my $width      = shift;
  my $height     = shift;

  my $update_sql = 
    qq{UPDATE layout } .
    qq{SET x_location=$x, y_location=$y, width=$width, height=$height } .
    qq{   WHERE categories = $cat_id };

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


=item html_header

=cut

sub html_header {
  my $self = shift;
  my $title = shift;
  my $spiel = shift || '';

  # my $heading = qq{<title>$title</title>};
  my $heading = '';

  my $css_file = $self->css_file || 'mah_moz_ohm.css';

  my $html = <<"__END_HTML_HEAD";
<!DOCTYPE html>
<html lang="en_US" dir="ltr">
<head>
<meta charset="utf-8">
$heading
<meta name="author" content="Joseph Brenner">
<link rel="stylesheet" type="text/css" href="$css_file">
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

sub css_header {
  my $self   = shift;
  my $height = shift || 150;
  my $height_str = $height . 'rem';
  my $css = <<"__END_CSS_HEAD";
body { 
  font-family: helvetica, verdana, arial, sans-serif;
}
/*  color:      #CC33FF; 
  background: #000000; 
*/

.container {
    position: relative;
    top:  2px;
    left: 30px;
    background: #99AAEE;
    border: dotted;
    height: $height_str;
}

.footsie {
    max-width:400px;
    background: lightgray;
}

.categories {
       background: yellow;
       border: solid 1px;
       padding: 2px;
       position: absolute;
}

__END_CSS_HEAD
  return $css;
}

=item html_footer

=cut

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

sub css_footer {
  my $self = shift;
  my $arg = shift;
  my $css = <<"__END_CSS_FOOT";
__END_CSS_FOOT
  return $css;
}



=item html_container_head

=cut

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
