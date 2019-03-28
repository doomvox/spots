#!/usr/bin/perl
# db_connect_probe.pl                   doom@kzsu.stanford.edu
#                                       21 Mar 2019

=head1 NAME

db_connect_probe.pl - (( TODO insert brief description ))

=head1 SYNOPSIS

  db_connect_probe.pl -[options] [arguments]

  TODO

=head1 DESCRIPTION

B<db_connect_probe.pl> is a script which

(( TODO  insert explanation
   This is stub documentation created by template.el.  ))

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

# Some very old code I've used to check pg db connect before.
# From: /home/doom/bin/dbi_in
#   -r-xr-xr-x  1 doom doom  1033 Feb  6  2007 dbi_in



use DBI;

my $dbname = "doom";
# TODO currently using a non-standard port. 
#      automatically finding the port would be cool...
my $port = '5434';
my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
my $username = 'doom';
my $auth = '';
my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
my $dbh = DBI->connect($data_source, $username, $auth, \%attr);

# Cute stuff.  Let's see what these do:
my @driver_names = DBI->available_drivers;
my @data_sources = DBI->data_sources('Pg'); 
my @names = $dbh->tables;  # pg_catalog and information_schema tables (long)

print "driver names:@driver_names\n";
print "data sources:\n@data_sources\n";  
print "names:\n@names\n";

my $sql = "SELECT 'hello' AS world";
my $sth = $dbh->prepare( $sql );
$sth->execute;
my $data = $sth->fetchall_arrayref({});
say Dumper( $data );







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

=head1 TROUBLESHOOTING

=over

=item Can not connect

DBI connect('dbname=doom','',...) failed: could not connect to server: No such file or directory
	Is the server running locally and accepting
	connections on Unix domain socket "/var/run/postgresql/.s.PGSQL.5432"? at /home/doom/End/Cave/Spots/bin/db_connect_probe.pl line 63.


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
