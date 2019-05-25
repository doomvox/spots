#!/usr/bin/env perl
# bounce_spots.pl                   doom@kzsu.stanford.edu
#                                   22 May 2019

# STATUS: working, but weak
#   fussy to use, perhaps necessarily so:
#   changing the schema means needing to clean the data,
#   and this can't help with that (yet?).

=head1 NAME

bounce_spots.pl - re-initialize the spots DATABASE

=head1 SYNOPSIS

  # demo run
  bounce_spots.pl 

  # live run
  bounce_spots.pl -L

  # with alternate DATABASE name
  bounce_spots.pl spots_test  -L


=head1 DESCRIPTION

B<bounce_spots.pl> is a script which drops a postgresql DATABASE ("spots" by default)
and re-initializes it by running the project's sql file (e.g. spots_schema.sql).

This is a simple method of accommodating schema changes during development.
When the project is completed there should be a schema "sql" file that can 
be easily used for initialization at a different site. 

TODO diving data backups from the schema would make sense if you're thinking 
about accomodating other users.

There are a number of safety features to reduce the risk of this process: 
at the outset there are two pg_dump invocations to save both schema and data 
in two different formats (doing your own backups first is also adviseable, of 
course).  

Note: this script has nothing to do with pgBouncer.

Issues: need to disconnect all users of the DATABASE you're going to recreate.
I had to do a restart:

  sudo /etc/init.d/postgresql restart

Issues:  the new schema and existing data may be incompatible:

  psql:spots_test_schema.sql:641: ERROR:  insert or update on table "spots" violates foreign key constraint "spots_category_fkey"
  DETAIL:  Key (category)=(4) is not present in table "category".



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
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );

our $VERSION = 0.01;
my  $prog    = basename($0);

my $LIVE = 0;  # TODO set to 1 when ready to run for real

my $VERBOSE = 0;
my $DEBUG   = 1;                 # TODO set default to 0 when in production
GetOptions ("d|debug"    => \$DEBUG,
            "V|verbose"  => \$VERBOSE,
            "L|live"     => \$LIVE,
            "v|version"  => sub{ say_version(); },
            "h|?|help"   => sub{ say_usage();   },
           ) or say_usage();
#           "length=i" => \$length,        # numeric
#           "file=s"   => \$file,          # string

$VERBOSE = 1; # TODO delete before ship

{ no warnings 'once'; $DB::single = 1; }

my $dbname     = shift || "spots";
my $log_loc    = "$HOME/End/Cave/Spots/Output";
my $backup_loc = "$HOME/End/Cave/Spots/Bak";  
my $sql_loc    = "$HOME/End/Cave/Spots/Wall/Spots/bin";  # TODO skull-specific loc better?

my $check_size = 10000; # refuse to run if pg_dump files aren't larger
# my $check_size = 0; # refuse to run if pg_dump files aren't larger

my $sql_file   = "$dbname" . "_schema.sql";

# my $date_stamp = "2019may22"; 
my $date_stamp = yyyy_month_dd();

my $backup_file   = "$dbname-$date_stamp.sql";
my $backup_r_file = "$dbname-$date_stamp-for_restore.sql";

chdir( $backup_loc );

# backup the backup files
if (-e $backup_file ) {
  copy( $backup_file, "$backup_file.BAK" );
}
if (-e $backup_r_file ) {
  copy( $backup_r_file, "$backup_file.BAK" );
}

my $backup_cmd = "pg_dump $dbname > $backup_file";
echo( "backup_cmd: ", $backup_cmd );
if( $LIVE ) { 
  system( $backup_cmd ) and die "$!: problem with back-up of db $dbname";
}

# doing a second backup that's pg_restore compatible
my $backup_r_cmd = "pg_dump --format=c $dbname > $backup_r_file";
echo( "backup_r_cmd: ", $backup_r_cmd );
if( $LIVE ) { 
  system( $backup_r_cmd ) and die "$!: problem with back-up of db $dbname for pg_restore";
}

#  sanitycheck the backup_file  (( TODO also grep for "^CREATE" ))
my $backup_size = (-s $backup_file) || 0;
unless( $backup_size > $check_size ) {
  if ($LIVE) { 
    die "Backup file looks too small (less than $check_size): $backup_size";
  } else {
    say "The backup_file: $backup_file is smaller than $check_size: but not live run: $backup_size.";
  }
}

my $db_drop_sql = "DROP DATABASE $dbname";
my $db_drop_sql_sh = shell_quote_best_effort( $db_drop_sql );
my $db_drop_cmd = "psql -d postgres -c $db_drop_sql_sh";
echo( "db_drop_cmd: ", $db_drop_cmd );
if( $LIVE ) { 
  system( $db_drop_cmd ) and die "$!: problem with dropping the old DATABASE $dbname";  
}

my $createdb_cmd = "createdb --owner=postgres $dbname";
echo( "createdb_cmd: ", $createdb_cmd );
if( $LIVE ) { 
  system( $createdb_cmd ) and die "$!: problem with creation of DATABASE $dbname";
}

chdir( $sql_loc );
my $sql_file_sh = shell_quote_best_effort( $sql_file );
my $load_schema_psql_cmd = "psql -d $dbname -f $sql_file_sh";
my $log_file     = "$log_loc/$dbname-$date_stamp.log"; # full path 
$log_file = uniquify( $log_file );
my $load_schema_cmd = "$load_schema_psql_cmd > $log_file 2>&1";
echo( "load_schema_cmd: ", $load_schema_cmd );
if( $LIVE ) { 
  system( $load_schema_cmd ) and die "$!: problem loading schema: $sql_file";
}

if ( -e $log_file ) { 
  open my $log_fh, '<', $log_file;
  undef $/;
  my $log = <$log_fh>;
  say $log if $VERBOSE;
} else {
  if( $LIVE ) {
    say STDERR "Can't find log file from loading schema: something is probably wrong."; 
  } else {
    say STDERR "Can't find log file from loading schema: but then, this is not a live run."; 
  }
}


### end main, into the subs

=item yyyy_month_dd

Returns the current date in a form like:

   2019may22 

=cut

sub yyyy_month_dd {
  my $time = shift || time;
  # my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my ($mday, $mon, $year) = ( localtime( $time ) )[3..5];
  $year += 1900;
  my @mon = qw(jan feb mar apr may jun jul aug sep oct nov dec);
  my $stamp = $year . $mon[ $mon ] . $mday;
  return $stamp;
}



=item echo

Usage:

  echo( "label: ", $string );

=cut

sub echo {
  my $label  = shift;
  my $string = shift;
  my $mess = sprintf( "%-17s %s", $label, $string );
  say STDERR $mess if $VERBOSE;
}


=item uniquify

Given a file name (typically with full path) checks to see if it
exists already, and if so munges a single character name suffix 
(just in front of the extension) to try to create a unique file 
name that doesn't exist yet.

For example, "/tmp/spots.log" might become "/tmp/spots-b.log".

Usage:

  my $file = uniquify( $file );

=cut


sub uniquify {
  my $file = shift;
  if( -e $file ) {
    my ( $lead, $ext, $new_file );
    if( $file =~ m{ ^ ( [^.]*? ) \. ( [^.]* ) $}x ) {
       $lead = $1;  
       $ext  = $2;

       # peel off a single character suffix, if any e.g. "-a"
       my $char = 'a';
       if ( $lead =~ s{ - ( [^-] ) $}{}x ) { 
         $char = $1;
       } 
       my $count = 0;
       do {
         $char = chr( ord( $char ) + 1);
         say STDERR "char: $char";
         $new_file = "$lead-$char.$ext";
         $count++;
       } until ( not( -e $new_file ) || $count > 10000 ); 
     }
    return $new_file;
  } else {
    return $file;
  }
}

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
