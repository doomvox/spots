package Spots::HomePage::Generate;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::HomePage::Generate - reads layout from db, writes html/css

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $DEBUG = 1; # TODO revise before shipping

=head1 SYNOPSIS

   use Spots::HomePage::Generate;
   my $basename = "my_browser_homepage";
   my $genner =
     Spots::HomePage::Generate->new(
                     output_basename  => $basename,
                     output_directory => $output_directory,
                  );
   $genner->html_css_from_layout();


   # just run on this over-ride list of category ids
   my @over_cats = (1, 23, 27, 66); 
   my $genner =
     Spots::HomePage::Generate->new(
                     output_basename  => $basename,
                     output_directory => $output_directory,
                     over_cats => \@over_cats,
                  );

=head1 DESCRIPTION

Spots::HomePage::Generate is a module that takes the page layout
from the database, and generates the html and css to display it.

Another module (in the Spots::HomePage::Layout tree) is soley in
charge of writing to the layout table.

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

use Spots::Config qw( $config );
use Spots::Herd;
use Spots::Category;
use Spots::DB::Handle;


=item new

Creates a new Spots::HomePage::Generate object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item debug 

Boolean, turns on some debugging messages, defaults to value of package global $DEBUG.

=item dbname 

The name of the DATABASE inside postgresql we will access.  Defaults to 'spots'.

=item output_basename  

Basename of the output file (will get ".html" of ".css" appended to it).

=item output_directory 

Location to write the output file.

=item color_scheme 

Either 'live' or 'dev', defaults to 'live'.   Chooses the default color scheme.

=item html_file 

Defaults to the full path: <output_directory>/<output_basename>.html
(largely for internal use: you might access this to find the generated file).

=item css_file  

Defaults to the full path: <output_directory>/<output_basename>.css
(largely for internal use: you might access this to find the generated file).

=item cat_herder 

The cat Herd object (restricted to over_cats, if in use).

=item all_cats   

An aref of all the Category objects we will display.

=item dbh         

Access to the dbh generated by Spots::DB::Handle for this dbname.

=item over_cats

An optional list of cat ids to override the "all_cats" look up.

=back

=cut

{ no warnings 'once'; $DB::single = 1; }

has debug => (is => 'rw', isa => Bool, default => sub{return $DEBUG});


has dbname  => (is => 'rw', isa => Str, default => $config->{ db_database_name } || 'spots' );

has output_basename  => (is => 'rw', isa => Str,
                        default => $config->{ output_file_basename }  || 'mah_moz_ohm');
has output_directory => (is => 'rw', isa => Str,
                         default => $config->{ output_directory }  || 'mah_moz_ohm');


# TODO rethink
# has color_scheme => (is => 'rw', isa => Str, default => 'dev' ); 
has color_scheme => (is => 'rw', isa => Str, default => 'live' ); # or 'dev'

has html_file => (is => 'rw', isa => Str, lazy => 1, builder => 'builder_html_file' );
has css_file  => (is => 'rw', isa => Str, lazy => 1, builder => 'builder_css_file' );

# TODO these two fh are not in use.
has html_fh => (is => 'rw', isa => InstanceOf['GLOB'], lazy => 1, builder => 'builder_html_fh' );
has css_fh  => (is => 'rw', isa => InstanceOf['GLOB'], lazy => 1, builder => 'builder_css_fh' );

has cat_herder => (is => 'rw', isa => InstanceOf['Spots::Herd'], lazy => 1,
                   builder => 'builder_cat_herder' );

has all_cats   => (is => 'rw', isa => ArrayRef[InstanceOf['Spots::Category']],
                   lazy=>1, builder => 'builder_all_cats' );

has dbh         => (is => 'rw', isa => InstanceOf['DBI::db'], lazy => 1,
                    builder => 'builder_db_connection' );


# optional list of cat ids to override the "all_cats" lookup-- 
# so you can use restricted sets for debugging purposes. 
has over_cats  => (is => 'rw', isa => ArrayRef[Int], lazy=>1,
                   default => sub{ [] } );

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


=item builder_db_connection

=cut

sub builder_db_connection {
  my $self = shift;
  my $dbname = $self->dbname;   # default 'spots'
  my $obj = Spots::DB::Handle->new({ dbname => $dbname });
  my $dbh = $obj->dbh;
  return $dbh;
}


=item builder_cat_herder

=cut

sub builder_cat_herder {
  my $self = shift;
  my $dbname = $self->dbname;
  my $over_cats = $self->over_cats;
  my $herd = Spots::Herd->new( dbname => $dbname, over_cats => $over_cats ); 
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



=item disconnect

=cut

sub disconnect {
  my $self = shift;
  my $dbh = $self->dbh;
  $dbh->disconnect;
}



=back 

=head2 output 

=over

=item html_css_from_layout

Generate the html and css files from the coordinates in the layout table.

=cut

sub html_css_from_layout {
  my $self = shift;

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

The color scheme as defined in Spots::Config by six colors.  

The object's 'color_scheme' chooses whether to use 'live' or 'dev' 
colors.

=cut

sub colors {
  my $self = shift;
  my $color_scheme = shift || $self->color_scheme;
  my %colors;
  my $black = '#000000';
  if ( $color_scheme eq 'dev' ) { 
    %colors = 
      (
       container_bg => $config->{ dev_color_container_bg } || '#225588',
       category_bg  => $config->{ dev_color_category_bg  } || '#BBDD00',
       footer_bg    => $config->{ dev_color_footer_bg    } || 'lightgray',
       anchor_fg    => $config->{ dev_color_anchor_fg    } || '#001111',
       
       anchor_visited_fg   => $config->{ color_anchor_visited_fg } || '#d8bfd8',  # orchid
       anchor_active_fg    => $config->{ color_anchor_active_fg } || 'red',
       anchor_hover_fg     => $config->{ color_anchor_hover_fg } || '#ff8c00',  # dark orange

       body_bg      => $config->{ dev_color_body_bg      } || '#000000',
       body_fg      => $config->{ dev_color_body_fg      } || '#CC33FF', 
      );
  } elsif ($color_scheme eq 'live' ) { 
    %colors = 
      (
       container_bg => $config->{ color_container_bg} || $black,
       category_bg  => $config->{ color_category_bg } || $black,
       footer_bg    => $config->{ color_footer_bg   } || $black,
       anchor_fg    => $config->{ color_anchor_fg   } || '#EFFFFF',

       anchor_visited_fg => $config->{ color_anchor_visited_fg } || '#DD99EE',  
       anchor_active_fg  => $config->{ color_anchor_active_fg }  || 'red',
       anchor_hover_fg   => $config->{ color_anchor_hover_fg }   || '#ff8c00',  # dark orange

       body_bg      => $config->{ color_body_bg     } || $black,
       body_fg      => $config->{ color_body_fg     } || $black,
      );
  }
  return \%colors;
}

=item html_header

=cut

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
<link rel="stylesheet" type="text/css" href="./$css_rel">
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


  my $color_scheme = $self->color_scheme;
  my $colors       = $self->colors( $color_scheme );
  my $container_bg = $colors->{ container_bg };
  my $category_bg  = $colors->{ category_bg };
  my $footer_bg    = $colors->{ footer_bg };
  my $anchor_fg    = $colors->{ anchor_fg };

  my $anchor_visited_fg = $colors->{ anchor_visited_fg };
  my $anchor_active_fg  = $colors->{ anchor_active_fg };
  my $anchor_hover_fg   = $colors->{ anchor_hover_fg };

  my $body_bg      = $colors->{ body_bg };
  my $body_fg      = $colors->{ body_fg };


  print STDERR "anchor_visited_fg: $anchor_visited_fg \n";
    
  my $css = <<"__END_CSS_HEAD";
body { 
  font-family: helvetica, verdana, arial, sans-serif;
}

a:link {
  color:      $anchor_fg
}

a:visited {
  color: $anchor_visited_fg;
}

a:hover {
  color: $anchor_hover_fg;
}

a:active {
  color: $anchor_active_fg;
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
