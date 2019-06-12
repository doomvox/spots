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
use Spots::Config qw( $config );
use Spots::HomePage::Layout::MetacatsFanout;
use Spots::HomePage::Generate;
use Spots::Rectangler;

use lib ("$Bin/../t/lib");
use Spots::Rectangle::TestData ':all';  # draw_placed

# my @over_cats = @ARGV; # optionally, a list of cat ids on the command-line 
my @over_cats = ();  # DEBUG feature

my $base =  $config->{ output_file_basename } || "mah_moz_ohm";
my $monster = 'Jimbanyan';
my $output_directory = $config->{ output_directory };
$output_directory .= "/$monster" if $monster;
mkpath( $output_directory ) unless -d $output_directory;

my $layo = Spots::HomePage::Layout::MetacatsFanout->new(
               db_database_name => $config->{ db_database_name },
               over_cats => \@over_cats,
            );

{no warnings 'once'; $DB::single = 1;}

# my $style;
# $style     = $config->{ default_layout_style } || 'metacats_fanout',
# say "Doing a $style run in $monster";
# $layo->generate_layout( $style );

$layo->generate_layout_metacats_fanout();

my $placed = $layo->placed;

my $tangler = Spots::Rectangler->new();
$tangler->draw_placed( $placed, $output_directory, 'placed', 2 );
my $report = $layo->check_placed( $placed );
say $report;

my $genner =
  Spots::HomePage::Generate->new(
               output_basename  => $base,
               output_directory => $output_directory,
               over_cats        => \@over_cats,
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
