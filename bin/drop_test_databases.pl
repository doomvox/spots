#!/usr/bin/env perl
# drop_test_databases.pl                   doom@kzsu.stanford.edu
#                                          16 Jun 2019

=head1 NAME

drop_test_databases.pl - drop test DATABASEs in your postgres installation

=head1 SYNOPSIS

  # list test dbnames (postgresql DATABASEs)
  drop_test_databases.pl --list

  # remove the test dbnames from your postgres installation
  drop_test_databases.pl 

=head1 DESCRIPTION

B<drop_test_databases.pl> is a script which removes left-over test databases 
but only if their names match a particular pattern.  

The --list or -L option can be used to just list the dbnames this script 
would target.  Running without those options does a live run that actually 
drops them.

=head2 motivation 

The Spots::HomePage test code creates new postgres DATABASEs (aka
dbnames) on the fly to do do completely independent tests.  
If the test code neglects to clean-up after itself, it may litter 
your postgres installation with peculiarly named dbnames like this:

    spots_fandango_31257_121839_test 
    spots_fandango_31358_122114_test 
    spots_fandango_3139_134333_test  
    spots_fandango_31507_122513_test 
    spots_fandango_31513_212220_test 

This is a script that cleans up those left-over DATABASEs
reasonably safely, by checking for *both* the *_test suffix and
the presence of two numeric fields before it (the pid and 
hhmmss). 

You can first do trial runs with this script (using --list or -L), 
just listing the matching dbnames without doing dropping them.

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
use Env             qw( HOME USER );
use String::ShellQuote qw( shell_quote );
use Config::Std;
use Getopt::Long    qw( :config no_ignore_case bundling );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );

our $VERSION = 0.01;
my  $prog    = basename($0);

my $DEBUG   = 1;  # TODO set default to 0 when in production
my $LIST    = 0;  # TODO set default to 0 when in production  
GetOptions ("d|debug"    => \$DEBUG,
            "v|version"  => sub{ say_version(); },
            "h|?|help"   => sub{ say_usage();   },
            "L|list"    => \$LIST,
           ) or say_usage();
#           "length=i" => \$length,        # numeric
#           "file=s"   => \$file,          # string

{ no warnings 'once'; $DB::single = 1; }

use FindBin qw( $Bin );
use lib "$Bin/../lib";  # perlnow should really find this location and use it TODO PERLNOW

use Spots::DB::Init;
use Spots::DB::Init::Namer;

my $namer = Spots::DB::Init::Namer->new();
my @dbnames = @{ $namer->list_databases };

#      [0-9]{6,6}
my $pat =
  qr{
      _
      [0-9]+
      _
      [0-9][0-9][0-9][0-9][0-9]+
      _test            # TODO get out of project configureation file
      $
  }x;

my @condemned = grep { /$pat/ } @dbnames;

if( $LIST ) {
  if (@condemned) { 
    say "Condemned test databases: \n   ", join "\n   ", @condemned;
  } else {
    say "No test databases found.";
  }
} else {
  # my $dbinit = Spots::DB::Init->new({ dbname => $dbname  });
  my $dbinit = Spots::DB::Init->new({ dbname  => $USER,
                                      live    => not( $LIST ),
                                    });

  foreach my $dbname ( @condemned ) {
    $dbinit->drop_test_db( $dbname );
  }
}

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
     -L          list run (lists, does not drop test dbnames)
     --list     list run (lists, does not drop test dbnames)

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
