package Spots::HomePage::Generate;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::HomePage::Generate - reads layout from db, writes html/css

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
my $DEBUG = 1; # TODO revise before shipping

=head1 SYNOPSIS

   use Spots::HomePage::Generate;
   my $obj = Spots::HomePage::Generate->new({ ...  });

   # TODO expand on this

=head1 DESCRIPTION

Spots::HomePage::Generate is a module that takes the page layout
from the database, and generates the homepage html and css to
display it.


Another module, Spots::HomePage::Layout ((?)) is soley in charge
of *writing* to the layout table, this code reads that data,
presuming that the layout has been defined already.

=head1 METHODS

=over

=cut

use 5.10.0;
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

use Spots::Herd;
use Spots::Category;
use Spots::DB::Handle;


=item new

Creates a new Spots::HomePage::Generate object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );

{ no warnings 'once'; $DB::single = 1; }

has debug => (is => 'rw', isa => Bool, default => sub{return ($DEBUG||0)});

has dbname => (is => 'rw', isa => Str, default => 'spots' );

has output_basename  => (is => 'rw', isa => Str,
                         default => 'moz_ohm' );
has output_directory => (is => 'rw', isa => Str,
                         default => "$HOME/End/Cave/Spots/Wall" );

# has color_scheme => (is => 'rw', isa => Str, default => 'live' ); # or 'dev'
has color_scheme => (is => 'rw', isa => Str, default => 'dev' ); 

has html_file => (is => 'rw', isa => Str, lazy => 1, builder => 'builder_html_file' );
has css_file  => (is => 'rw', isa => Str, lazy => 1, builder => 'builder_css_file' );

has html_fh => (is => 'rw', isa => InstanceOf['GLOB'], lazy => 1, builder => 'builder_html_fh' );
has css_fh  => (is => 'rw', isa => InstanceOf['GLOB'], lazy => 1, builder => 'builder_css_fh' );

has cat_herder => (is => 'rw', isa => InstanceOf['Spots::Herd'], lazy => 1,
                   builder => 'builder_cat_herder' );

has all_cats   => (is => 'rw', isa => ArrayRef[InstanceOf['Spots::Category']],
                   lazy=>1, builder => 'builder_all_cats' );

has dbh         => (is => 'rw', isa => InstanceOf['DBI::db'], lazy => 1,
                    builder => 'builder_db_connection' );

# GENHTML  reads from layout table
has sth_cat_size      => (is => 'rw', isa => InstanceOf['DBI::st'], lazy => 1,
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

# =item builder_db_connection

# =cut

# sub builder_db_connection {
#   my $self = shift;

#   # TODO break-out more of these params as object fields
#   # TODO add a secrets file to pull auth info from
#   my $dbname = $self->dbname; # default 'spots'
#   # my $port = '5434'; # non-standard port for old build on tango
#   my $port = '5432';
#   my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
#   my $username = 'doom';
#   my $auth = '';
#   my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
#   my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
#   return $dbh;
# }


=item builder_db_connection

=cut

sub builder_db_connection {
  my $self = shift;
  my $dbname = $self->dbname;   # default 'spots'
  my $obj = Spots::DB::Handle->new({ dbname => $dbname });
  my $dbh = $obj->dbh;
  return $dbh;
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



=item builder_cat_herder

=cut

sub builder_cat_herder {
  my $self = shift;
  my $dbname = $self->dbname;
  my $herd = Spots::Herd->new(  dbname => $dbname ); 
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
    $self->maximum_height_and_width_of_layout;   ### TODO 

  my $css_head = $self->css_header( $container_height );
  print {$css_fh} $css_head;

  # my $all_cats = $self->list_all_cats;   
  my $all_cats = $self->all_cats;

  my ($rp_count, $max_h)  = (0, 0);
  foreach my $cat ( @{ $all_cats } ) {
    my $cat_id    = $cat->id;
    my $cat_name  = $cat->name;

#     my ($cat_spots, $spot_count, $x, $y, $w, $h) = 
#       $self->lookup_cat_and_size( $cat_id );  

    my $cat_spots  = $cat->spots;
    my $spot_count = $cat->spot_count;
    my $x          = $cat->x_location;
    my $y          = $cat->y_location;
    my $w          = $cat->width;
    my $h          = $cat->height;

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

    if( $self->debug ) {
      $cat_html =~ s{<br>$}{<b>*$cat_id*</b><br>}x; ### DEBUG
      $cat_html .= "$cat_id: $cat_name"; ### DEBUG
    }

    $cat_html .= qq{</div>\n};

    # print block to the html handle
    print {$html_fh} $cat_html, "\n";

    # css for the category                    
    my $x_str = $x . 'px';
    my $y_str = $y . 'rem'; 

    my $w_str  = $w . 'px';  # estimated width to fit number of chars.
    my $h_str  = $h . 'rem'; # height sized for the number of lines

# # TODO this doesn't work (?) (( could it be the indentation of the # at start? ))
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


=item maximum_height_and_width_of_layout

Determine the height (rem) and width (px) of the layout.

Example usage:

  my ($height, $width) = 
    $self->maximum_height_and_width_of_layout;

=cut

# GENHTML
sub maximum_height_and_width_of_layout {    # TODO warn if there's no x/y values yet?
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
