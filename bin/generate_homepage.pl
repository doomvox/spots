#!/usr/bin/env perl
#!/usr/bin/perl
# generate_homepage.pl                   doom@kzsu.stanford.edu
#                                        30 Mar 2019

=head1 NAME

generate_homepage.pl - generate mah_moz.html from spots db

=head1 SYNOPSIS

  # put output files in current directory
  generate_homepage.pl

=head1 DESCRIPTION

B<generate_homepage.pl> is a script which generates one of my standard
"browser homepages" (a collection of links tersely labeled and arranged 
in a tight one-screen layout).

It uses these spots db tables to drive the process:
  spots, category, metacats

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
GetOptions ("d|debug"    => \$DEBUG,
            "v|version"  => sub{ say_version(); },
            "h|?|help"   => sub{ say_usage();   },
           ) or say_usage();
#           "length=i" => \$length,        # numeric
#           "file=s"   => \$file,          # string

{ no warnings 'once'; $DB::single = 1; }
# use Spots::HomePage; b Spots::HomePage::generate_layout_metacats_fanout

use FindBin qw($Bin);
use lib ("$Bin/../lib/");
# use Spots::HomePage; 
use Spots::HomePage::Layout::MetacatsFanout;
use Spots::HomePage::Generate;

use lib ("$Bin/../t/lib");
use Spots::Rectangle::TestData ':all';  # draw_placed

my @over_cats = @ARGV; # optionally, a list of cat ids on the command-line 

#DEBUG
# @over_cats = qw( 12 32 55 5 );
# @over_cats = qw( 1 2 3 4 );
# @over_cats = qw( 1 2 3  );
@over_cats = ();

say Dumper( \@over_cats ) if @over_cats;

# TODO rethink:
## my $base             = shift || "mah_moz_ohm";
my $base             =  "mah_moz_ohm";
my $monster = 'Akkorokamui';
# my $output_directory = shift || "/home/doom/End/Cave/Spots/Output/$monster"; 
my $output_directory = "/home/doom/End/Cave/Spots/Output/$monster"; 

mkpath( $output_directory ) unless -d $output_directory;

# TODO ultimately, use:
# my $output_directory = "$HOME/End/Stage/Rook/spots";

my $obj = Spots::HomePage::Layout::MetacatsFanout->new(
#                               output_basename  => $base,
#                               output_directory => $output_directory,
                               db_database_name => 'spots',
#                               db_database_name => 'spots_test',
                               over_cats => \@over_cats,
                              );

{no warnings 'once'; $DB::single = 1;}

# my $style;
# $style     = 'metacats_fanout',
# say "Doing a $style run in $monster";
# $obj->generate_layout( $style );

$obj->clear_layout;

$obj->generate_layout_metacats_fanout();

my $placed = $obj->placed;

# draw_placed( $placed, $output_directory, 'placed', 2 );
use Spots::Rectangler;
my $tangler = Spots::Rectangler->new();
$tangler->draw_placed( $placed, $output_directory, 'placed', 2 );

{ no warnings 'once'; $DB::single = 1; }
my $report = $obj->check_placed( $placed );

say $report;


my $genner =
  Spots::HomePage::Generate->new(
                               output_basename  => $base,
                               output_directory => $output_directory,
                               over_cats => \@over_cats,
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
