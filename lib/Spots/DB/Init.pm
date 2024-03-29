package Spots::DB::Init;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::DB::Init - utility to manipulate the spots database

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::DB::Init;
   use Spots::DB::Namer;

   my $namer = Spots::DB::Init::Namer->new();
   my $dbname = $namer->uniq_database_name;  

   my $dbinit = Spots::DB::Init->new({ dbname => $dbname  });

   # TODO expand on this

=head1 DESCRIPTION

Spots::DB::Init is a module that contains utility commands to
manipulate the spots database as a whole.

The immediate motivation is to provide safer(er) ways of
dropping and creating a spots DATABASE inside of postgresql.

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
use Env             qw( HOME USER );
use List::Util      qw( first max maxstr min minstr reduce shuffle sum any );
use List::MoreUtils qw( zip uniq );
use String::ShellQuote qw( shell_quote );
use Spots::Config qw( $config );
use Spots::DB::Init::Namer;

# use Config::INI::Writer;
# use JSON;
use Config::Std;


# use DBI;  # at present this is unnecessary

=item new

Creates a new Spots::DB::Init object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item dbname

The name of the postgresql DATABASE to act on.  
This also gets used internally as the naming_prefix.

<TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

{ no warnings 'once'; $DB::single = 1; }

# TODO for a dbname default we could do this, but this code is not really intended for tests only,
# but for initializing a new db for the spots project:
# 
# default => sub{ 
#    my $namer = $self->db_init_namer;
#    my $dbname = $namer->uniq_database_name;  
# }

# This code builds up later locations using spots_loc as root.
# This is
#  o  a verbose and effcient way to build a few strings (burning a lot of method calls)
#  o  very specific to the way I'm working at present: not general enough to ship
#  On the plus side, having them exposed as object fields makes them easy
#  to over-ride... but good defaults would be good, no? 

# Okay: default for *.sql files could be in parallel with the progloc from $0.
# log and backup locations... could default to /tmp?  No: subdirs of 
# spots_loc, and spots_loc can default to /tmp?  

# That would mean that my defaults are locations that I would never use:
# I think some sort of standard approach to project-configuration is in order,
# like Config::Ini?  You pass in a config file location to everything in the project?
# A standard envar with the config file name and path?  A naming convention to
# find a config file for $0? 


# Name of the DATABASE inside postgres to act on
has dbname => ( is => 'rw', isa => Str, default => 'spots_test' );  # TODO 'spots' when live

# flags
has live    => ( is => 'rw', isa => Bool, default => 0 );  # if not set, just a dry run
has verbose => ( is => 'rw', isa => Bool, default => 0 );
has debug   => ( is => 'rw', isa => Bool, default => 0 );
has unsafe  => ( is => 'rw', isa => Bool, default => 0 );  

# TODO default locations are tuned up for the way I'm working-- revise if shipped
has spots_loc   => ( is => 'rw', isa => Str, default => "$HOME/End/Cave/Spots" ); 
has log_loc     => ( is => 'rw', isa => Str, lazy=>1, 
                     default => sub{ my $self = shift;
                                     my $spots_loc=$self->spots_loc;
                                     my $loc = "$spots_loc/Output";
                                     return $loc;
                                   } ); 
has backup_loc  => ( is => 'rw', lazy=>1, isa => Str,
                     default => sub{ my $self = shift;
                                     my $spots_loc=$self->spots_loc;
                                     my $loc = "$spots_loc/Bak";
                                     return $loc;
                                   } ); 

has db_schema_loc  => ( is => 'rw', lazy=>1, isa => Str,
                     default => sub{ my $self = shift;
                                     my $spots_loc=$self->spots_loc;
                                     my $loc = "$spots_loc/Wall/Spots/bin";
                                     return $loc;
                                   } ); 

has db_data_loc    => ( is => 'rw', lazy=>1, isa => Str,
                     default => sub{ my $self = shift;
                                     my $spots_loc = $self->spots_loc;
                                     my $loc = "$spots_loc/Wall/Spots/bin";
                                     return $loc;
                                   } ); 

# refuse to drop a DATABASE that doesn't match one of these (unless 'unsafe')
has dbname_safety_pats => ( is => 'rw', isa => ArrayRef, default => sub{ [ qr(_test$) ] } );
# refuse to run if pg_dump backup files aren't larger than this
has pg_dump_min_size   => ( is => 'rw', isa => Num,      default => 1000 );

has naming_prefix => ( is => 'rw', isa => Str,
                         default => sub{ my $self = shift;
                                         my $naming_prefix = $self->dbname;   # e.g. 'spots'
                                         return $naming_prefix;
                                       } ); 

has schema_backup_file => ( is => 'rw', isa => Str, lazy=>1,
                          default => sub { my $self = shift;
                                           my $date_stamp = $self->yyyy_month_dd();  # e.g. "2019may22"
                                           my $naming_prefix = $self->naming_prefix;
                                           my $name = "$naming_prefix-schema-$date_stamp.sql";
                                           my $loc  = $self->backup_loc;
                                           my $full = "$loc/$name";
                                           my $uni  = $self->uniquify( $full );
                                           return $uni;
                                         }  ); 

has data_backup_file => ( is => 'rw', isa => Str, lazy=>1,
                          default => sub { my $self = shift;
                                           my $date_stamp = $self->yyyy_month_dd();  # e.g. "2019may22"
                                           my $naming_prefix = $self->naming_prefix;
                                           my $name = "$naming_prefix-data-$date_stamp.sql";
                                           my $loc  = $self->backup_loc;
                                           my $full = "$loc/$name";
                                           my $uni  = $self->uniquify( $full );
                                           return $uni;
                                         }  ); 

has pg_restore_file => ( is => 'rw', isa => Str, lazy=>1,
                             default => sub { my $self = shift;
                                              my $date_stamp = $self->yyyy_month_dd(); # e.g. "2019may22"
                                              my $dbname = $self->dbname;
                                              my $name = "$dbname-$date_stamp.pg_restore";
                                              my $loc  = $self->backup_loc;
                                              my $full = "$loc/$name";
                                              my $uni  = $self->uniquify( $full );
                                              return $uni;
                                            }  ); 

has log_file => ( is => 'rw', isa => Str, lazy=>1,
                             default => sub { my $self = shift;
                                              my $date_stamp = $self->yyyy_month_dd(); # e.g. "2019may22"
                                              my $naming_prefix = $self->naming_prefix;
                                              my $name = "$naming_prefix-$date_stamp.log";
                                              my $loc  = $self->log_loc;
                                              my $full = "$loc/$name";
                                              my $uni  = $self->uniquify( $full );
                                              return $uni;
                                            }  ); 

has db_schema_file => ( is => 'rw', isa => Str, lazy=>1,
                             default => sub { my $self = shift;
                                              my $naming_prefix = $self->naming_prefix;
                                              my $name = "$naming_prefix-schema.sql";
                                              my $loc  = $self->db_schema_loc;
                                              my $full = "$loc/$name";
                                              return $full;
                                            }  ); 


has db_data_file => ( is => 'rw', isa => Str, lazy=>1,
                             default => sub { my $self = shift;
                                              my $dbname = $self->dbname;
                                              my $name = "$dbname-data.sql";
                                              my $loc  = $self->db_data_loc;
                                              my $full = "$loc/$name";
                                              return $full;
                                            }  ); 


has db_init_namer => ( is => 'rw', isa => InstanceOf['Spots::DB::Init::Namer'], lazy=>1,
                             default => sub { my $self = shift;
                                              my $namer = Spots::DB::Init::Namer->new();
                                              return $namer;
                                            }  );                                               

has yyyy_month_dd => ( is => 'ro', isa => Str, lazy=>1, builder => 'builder_yyyy_month_dd' );

=item builder_yyyy_month_dd

=cut

sub builder_yyyy_month_dd {
  my $self = shift;
  my $namer = $self->db_init_namer;
  my $yyyy_month_dd = $namer->yyyy_month_dd;
  return $yyyy_month_dd;
}




=item backup_db

Example usage:

  $self->backup_db();

=cut

sub backup_db {
  my $self = shift;
  my $dbname = $self->dbname;
  my $live = $self->live;

  # Note: all include full path:
  my $schema_backup_file = $self->schema_backup_file;
  my $data_backup_file   = $self->data_backup_file;
  my $pg_restore_file    = $self->pg_restore_file;

  # backup the backup files
  my @bu_fn = ( $schema_backup_file,  $data_backup_file, $pg_restore_file );
  $self->backup_the_backup_files( \@bu_fn );

  my $backup_schema_cmd = "pg_dump --schema-only $dbname > $schema_backup_file"; 
  $self->safe_system( $backup_schema_cmd, "backup_schema_cmd" );

  my $backup_data_cmd = "pg_dump --data-only $dbname > $data_backup_file";     
  $self->safe_system( $backup_data_cmd, "backup_data_cmd" );

  # doing a second backup that's pg_restore compatible
  my $backup_r_cmd = "pg_dump --format=c $dbname > $pg_restore_file";
  $self->safe_system( $backup_r_cmd, "backup_r_cmd" );

  my $ret = $self->sanity_check_backup_files;  # Note: croaks on failure
  return $ret;
}


=item backup_the_backup_files

=cut

sub backup_the_backup_files {
  my $self = shift;
  my $bu_fns = shift;
  foreach my $bu_fn ( @{ $bu_fns } ) { 
    if (-e $bu_fn ) {
      my $bu2_fn = "$bu_fn.BAK";
      $bu2_fn = $self->uniquify( $bu2_fn );
      copy( $bu_fn, $bu2_fn ); 
    }
  }
}

=item sanity_check_backup_files

=cut

sub sanity_check_backup_files {
  my $self = shift;

  my $live = $self->live;

  # Note: all include full path:
  my $schema_backup_file = $self->schema_backup_file;
  my $data_backup_file   = $self->data_backup_file;
  my $pg_restore_file    = $self->pg_restore_file;

  my $pg_dump_min_size = $self->pg_dump_min_size;

  #  TODO also grep for "^CREATE" in schema file, etc.

  my $backup_size;
  $backup_size = (-s $schema_backup_file) || 0;
  unless( $backup_size > $pg_dump_min_size ) {
    if ( $live ) { 
      croak
        "Backup file looks too small (less than " .
        "$pg_dump_min_size): $backup_size";
    } else {
      say
        "The backup_file: $schema_backup_file is smaller than " .
        "$pg_dump_min_size: but this is not a live run.";
    }
  }

  $backup_size = (-s $data_backup_file) || 0;
  unless( $backup_size > $pg_dump_min_size ) {
    if ( $live ) { 
      croak
        "Backup file looks too small (less than " .
        "$pg_dump_min_size): $backup_size";
    } else {
      say
        "The backup_file: $data_backup_file is smaller than " .
        "$pg_dump_min_size: but this is not a live run.";
    }
  }

  $backup_size = (-s $pg_restore_file) || 0;
  unless( $backup_size > $pg_dump_min_size ) {
    if ( $live ) { 
      croak
        "Backup file looks too small (less than " .
        "$pg_dump_min_size): $backup_size";
    } else {
      say
        "The backup_file: $pg_restore_file is smaller than " .
        "$pg_dump_min_size: but this is not a live run.";
    }
  }
  return 1;  # TODO any better retval?
}


=item drop_test_db

=cut

sub drop_test_db {
  my $self = shift;
  my $dbname = shift || $self->dbname;
  my $live   = $self->live;
  my $unsafe = $self->unsafe;
  my $verbose = $self->verbose;

  say STDERR "Running drop_test_db on dbname $dbname" if $verbose;
  unless( $unsafe ) { 
    croak "seeing spots"                                if ($dbname eq 'spots'); # TODO comment out when shipped
    croak "Attempt at dropping DATABASE postgres"       if ($dbname eq 'postgres');
    croak "Attempt at dropping user's DATABASE: $USER"  if ($dbname eq $USER);  # e.g. 'doom'
    croak "Attempt at dropping template0"               if ($dbname eq 'template0');
    croak "Attempt at dropping template1"               if ($dbname eq 'template1');

    my $dbname_safety_pats = $self->dbname_safety_pats;
    unless( any { $dbname =~ m/$_/ } @{ $dbname_safety_pats } ) {
      croak "$dbname does not match one of dbname_safety_pats"
    }
  }

  my $namer = $self->db_init_namer;
  if( $namer->db_exists( $dbname ) ) { 
    my $db_drop_sql = "DROP DATABASE $dbname";
    my $db_drop_sql_sh = shell_quote( $db_drop_sql );
    my $db_drop_cmd = "psql -d postgres -c $db_drop_sql_sh";
    $self->safe_system( $db_drop_cmd, "db_drop_cmd" );
  } else {
    carp "This $dbname does not exist we will skip trying to drop it: $dbname";
  }
}



=item create_db

=cut

sub create_db {
  my $self = shift;
  my $dbname = $self->dbname;
  my $live = $self->live;
  # TODO check if DATABASE exists already?  (( code in namer can do that... ))
  my $createdb_cmd = "createdb --owner=postgres $dbname";
  $self->safe_system( $createdb_cmd, "createdb_cmd" );
}



=item load_schema

Example usage

  # optionally, clear log file first?  #TODO 
  $self->load_schema;  # appends to log_file
  $self->load_data;    # appends to log_file
  $self->echo_the_log;

=cut

sub load_schema {
  my $self = shift;
  my $dbname = $self->dbname;

  my $log_file = $self->log_file;

  my $db_schema_file = $self->db_schema_file;
  
  my $sql_file_sh = shell_quote( $db_schema_file );
  my $load_schema_psql_cmd = "psql -d $dbname -f $sql_file_sh";

  my $load_schema_cmd = "$load_schema_psql_cmd >> $log_file 2>&1";
  $self->safe_system( $load_schema_cmd, "load_schema_cmd" );
}


=item load_data

=cut

sub load_data {
  my $self = shift;
  my $dbname = $self->dbname;
  my $log_file     = $self->log_file;
  my $db_data_file = $self->db_data_file;
  
  my $db_data_file_sh = shell_quote( $db_data_file );
  my $load_db_data_psql_cmd = "psql -d $dbname -f $db_data_file_sh";

  my $load_db_data_cmd = "$load_db_data_psql_cmd >> $log_file 2>&1";
  $self->safe_system( $load_db_data_cmd, "load_db_data_cmd" );
}


=item echo_the_log

=cut

sub echo_the_log {
  my $self     = shift;
  my $log_file = shift || $self->log_file;
  my $live     = $self->live;
  my $verbose  = $self->verbose;

  if ( -e $log_file ) { 
    open my $log_fh, '<', $log_file;
    undef $/;
    my $log = <$log_fh>;
    say $log if $verbose;
  } else {
    if ( $live ) {
      carp "Can't find log file: something is probably wrong: \n$log_file."; 
    } else {
      carp "Can't find log file: but then, this is not a live run: \n$log_file"; 
    }
  }
}








=back

=head2  utility methods

# =item yyyy_month_dd

# Returns the current date in a form like:

#    2019may22 

# =cut

# ### TODO also exists in Namer.  Use from there, not here.
# sub yyyy_month_dd {
#   my $self = shift;
#   my $time = shift || time;
#   my ($mday, $mon, $year) = ( localtime( $time ) )[3..5];
#   $year += 1900;
#   my @mon = qw(jan feb mar apr may jun jul aug sep oct nov dec);
#   my $stamp = $year . $mon[ $mon ] . $mday;
#   return $stamp;
# }


=item uniquify

Given a file name (typically with full path) checks to see if it
exists already, and if so munges a single character name suffix 
(just in front of the extension) to try to create a unique file 
name that doesn't exist yet.

For example, "/tmp/spots.log" might become "/tmp/spots-b.log".

Usage:

  my $file = $self->uniquify( $file );

=cut


sub uniquify {
  my $self = shift;
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


=item echo_cmd

Usage:

  $self->echo_cmd( "label: ", $string );

=cut

sub echo_cmd {
  my $self = shift;
  my $label  = shift;
  my $string = shift;
  my $verbose = $self->verbose;

  my $mess = sprintf( "%-17s: %s", $label, $string );
  say STDERR $mess if $verbose;
}

=item safe_system

Well, safer anyway.  Wrapper around the system command.  
Echos given command, and only runs it if object's "live" flag is set.

Usage:

  $self->safe_system( $string, "label" );

=cut

sub safe_system {
  my $self = shift;
  my $cmd  = shift;
  my $mess = shift || '';

  my $live = $self->live;

  $self->echo_cmd( $mess, $cmd );
  if ( $live ) { 
    system( $cmd ) and die "$mess  $!";
  }
}

=item write_config_std_file

Write object keys to a Config::Std format *.cfg file.

=cut

sub write_config_std_file {
  my $self = shift;
  my $file = shift || "$HOME/tmp/spottey.cfg";

  my $class = ref $self;
  my %hashola = ( %{$self} );

  # A hash of hashes keyed by class (so other modules can use same file)
  my %out = ( $class => \%hashola );
  write_config %out, $file;
}





=over 

=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
25 May 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
