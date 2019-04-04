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
use Data::Dumper;

use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use autodie         qw( :all mkpath copy move ); # system/exec along with open, close, etc
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );
use String::ShellQuote qw( shell_quote_best_effort );
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

# $DB::single = 1;
# b Spots::HomePage::generate_layout_for_row

use FindBin qw($Bin);
use lib ("$Bin/../lib/");
use Spots::HomePage; 

# TODO rethink:
my $base             = shift || "mah_moz";
# my $output_directory = shift || cwd();  # First re-think: I hate pwd as default
my $output_directory = shift || "/home/doom/End/Cave/Spots/Output/Three"; # temporary

my $obj = Spots::HomePage->new(
                               output_basename  => $base,
                               output_directory => $output_directory,
                               db_database_name => 'spots',
                              );


# TODO does this help? (Q: how hard to add rollback-like feature?)
# # wipe the coordinate columns in the layout table
# $obj->clear_layout;

# my $style   = "metacats";
my $style   = "metacats_doublezig";
$obj->generate_layout( $style );

$obj->html_css_from_layout();

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
