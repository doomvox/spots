package Spots::Config;
#                                doom@kzsu.stanford.edu
#                                10 Jun 2019


=head1 NAME

Spots::Config - system-wide configuration defaults for Spots

=head1 SYNOPSIS

   use Spots::Config qw( $config );
   my $output_directory = $config->{ output_directory };

   # This works also
   use Spots::Config ':all';


=head1 DESCRIPTION

TODO  Stub documentation for Spots::Config,
created by perlnow.el using template.el.

It looks like the author of the extension was negligent
enough to leave the stub unedited.

=head2 EXPORT

None by default.  Optionally:

=over

=cut

use 5.10.0;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use autodie         qw( :all mkpath copy move ); # system/exec along with open, close, etc
use Cwd             qw( cwd abs_path );
use Env             qw( HOME USER );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );
use String::ShellQuote qw( shell_quote );


our (@ISA, @EXPORT_OK, %EXPORT_TAGS, @EXPORT);
BEGIN {
 require Exporter;
 @ISA = qw(Exporter);
 %EXPORT_TAGS = ( 'all' => [
 qw(
     $config
    ) ] );
  # The above allows declaration	use Spots::Config ':all';

  @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
  @EXPORT = qw(  ); # items to export into callers namespace by default (avoid this!)
#  $DB::single = 1;
}

our $VERSION = '0.01';
my $DEBUG = 1;

=item $config

$config is a reference to a hash of key-value parameters, 
a set of system-wide defaults for all of the Spots code.

=cut 


our $config =
  {
#   output_file_basename => 'mah_moz_ohm',
   output_file_basename => 'spots_central',
   # output_directory   => "$HOME/End/Stage/Rook/spots",
   output_directory     => "$HOME/End/Cave/Spots/Output",
   db_database_name     => 'spots',  # aka dbname
   default_layout_style => 'metacats_fanout',

   # Spots::Homepage::Layout  (( TODO ))
   layout_style =>  'metacats_fanout' , 

   # Spots::Homepage::Layout::MetacatsFanout
   top_bound   =>  0 ,
   left_bound  =>  0 ,
   bot_bound   =>  10000 ,  # big numbers for now
   right_bound =>  10000 ,

   # used by metacats_fanout, find_hole_for_cat_thataway
   nudge_x   =>  1 ,  # rem   was 1.5
   nudge_y   =>  4 ,  # px    was 6

   initial_y =>  0    , # rem 
   initial_x =>  4    , # px

   # Spots::Homepage::Generate
   # 'live'
   color_container_bg => '#0f0f0f',
   color_category_bg  => '#000000',
   color_footer_bg    => '#000000',
   color_anchor_fg    => '#BBCCFF',
   color_anchor_visited_fg   => '#9932cc',  # orchid
   color_anchor_active_fg    => 'red',
   color_anchor_hover_fg     => '#ff8c00',  # dark orange
   color_body_bg      => '#000000',
   color_body_fg      => '#556b2f',  # dark olive green

    # 'dev' (an alternate color scheme)
   dev_color_container_bg => '#225588',
   dev_color_category_bg  => '#BBDD00',
   dev_color_footer_bg    => 'lightgray',
   dev_color_anchor_fg    => '#001111',
   ## other anchor colors just use 'live' versions for now
   dev_color_body_bg      => '#000000',
   dev_color_body_fg      => '#CC33FF', 

   # Spots::Rectangler  draw_placed
   png_canvas_width     => 1800,
   png_canvas_height    => 900,
   png_x_scale          => 1.5,
   png_y_scale          => 1.5*3,
   png_dwg_offset       => 30,
   png_dwg_thickness    => 3, 

   rectangle_y_weight   => 6.5,  # eventually use project px_per_rem figure

   category_x_scale     => 10,    # average px per char
   category_y_scale     => 1.32,  # rem per line

   # Spots::DB::Handle
   port        =>  '5432',
   username    =>  $USER,
   auth        =>  '',
   autocommit  =>  1,
   raise_error =>  1,
   print_error =>  0,

   };

1;

=back


=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut
