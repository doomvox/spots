#!/usr/bin/env perl
#!/usr/bin/perl
# generate_homepage.pl                   doom@kzsu.stanford.edu
#                                        30 Mar 2019

=head1 NAME

generate_homepage.pl - generate mah_moz.html from spots db

=head1 SYNOPSIS

  ## Before running: check the settings in Spots::Config

  ## generate output in the Jimbanyan subdirectory inside of the Config.pm 'output_directory'
  generate_homepage.pl -S Jimbanyan

  ## same, using special basename "mah_moz_ohm":
  generate_homepage.pl -S Jimbanyan  -B mah_moz_ohm

  ## generate output in the given output directory, ignoring the Config.pm
  generate_homepage.pl -O '/tmp/output'



=head1 DESCRIPTION

B<generate_homepage.pl> is a script which generates one of my standard
"browser homepages" (a collection of links tersely labeled and arranged 
in a tight one-screen layout).

It uses these spots db tables to drive the process:
  spots, category, metacats

The module Spots::Config has an output_directory field, which by
default is where this script places the generated files (one
.html and one .css):

     output_directory     => "$HOME/End/Cave/Spots/Output",

The output_file_basename in Config.pm controls the basename of the files:

    output_file_basename => 'mah_moz_ohm',

  
=head2 personal notes

  When done, pages can be pushed live by doing something like this:
  
    cd /home/doom/End/Cave/Spots/Output/Jimbanyan
    scp mah_moz_ohm.* doomvox@shell.sonic.net:/home2/14/09/doomvox/public_html/obsidianrook.com/spots

  Note, sonic.net likes to mess you up with that mangled path.
  Might have to check it.


=cut

use 5.10.0;
use warnings;
use strict;
$|=1;
use Carp;
use Data::Dumper::Names;

use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use autodie         qw( :all mkpath copy move ); # system, exec, open, close...
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use String::ShellQuote qw( shell_quote shell_quote_best_effort );
use Config::Std;
use Getopt::Long    qw( :config no_ignore_case bundling );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum );
use List::MoreUtils qw( any zip uniq );

our $VERSION = 0.01;
my  $prog    = basename($0);

my $DEBUG   = 1;                 # TODO set default to 0 when in production
my $SUBDIR  = ''; 
my $OUTLOC  = '';
my $BASENAME = '';
GetOptions ("d|debug"    => \$DEBUG,
            "v|version"  => sub{ say_version(); },
            "h|?|help"   => sub{ say_usage();   },
            "S|subdir=s"   => \$SUBDIR,   # e.g. 'Jimbanyan'
            "O|outloc=s"   => \$OUTLOC,   #
            "B|basename=s" => \$BASENAME,
           ) or say_usage();
#           "length=i" => \$length,        # numeric
#           "file=s"   => \$file,          # string

{ no warnings 'once'; $DB::single = 1; }

use FindBin qw($Bin);
use lib ("$Bin/../lib/");
# use Spots::HomePage; 
use Spots::Config qw( $config );
use Spots::HomePage::Layout::MetacatsFanout;
use Spots::HomePage::Generate;
use Spots::Rectangler;

use lib ("$Bin/../t/lib");
use Spots::Rectangle::TestData ':all';  # draw_placed

my @over_cats = ();  # DEBUG feature

my $output_directory = $config->{ output_directory };
if( $OUTLOC ) {
  $output_directory = $OUTLOC;
} elsif ( $SUBDIR ) {
  $output_directory .= "/$SUBDIR";
}  
mkpath( $output_directory ) unless -d $output_directory;

my $output_basename = $BASENAME || $config->{ output_file_basename }; ## e.g. "mah_moz_ohm";

my $layo = Spots::HomePage::Layout::MetacatsFanout->new(
               db_database_name => $config->{ db_database_name },
               over_cats => \@over_cats,
            );
$layo->generate_layout_metacats_fanout();
my $placed = $layo->placed;

my $tangler = Spots::Rectangler->new();
$tangler->draw_placed( $placed, $output_directory, 'placed', 2 );
my $report = $tangler->check_placed( $placed );
say $report;

my $genner =
  Spots::HomePage::Generate->new(
               output_basename  => $output_basename,
               output_directory => $output_directory,
               over_cats        => \@over_cats,
               color_scheme     => 'live',
            );
$genner->html_css_from_layout();

# TODO check whether expected file has been created/modified



### end main, into the subs

sub say_usage {
  my $usage=<<"USEME";
  $prog -[options] [arguments]

  Options:
     -d          debug messages on
     --debug     same
     -h          help (show usage)
     -v          show version
     --version   show version

TODO add additional options

USEME
  print "$usage\n";
  exit;
}

sub say_version {
  print "Running $prog version: $VERSION\n";
  exit 1;
}


__END__

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
