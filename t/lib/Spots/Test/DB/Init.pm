package Spots::Test::DB::Init;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::Test::DB::Init - methods to set-up test dbs for the spots project tests

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::Test::DB::Init;
   my $obj = Spots::Test::DB::Init->new({ ...  });

   # TODO expand on this

   $self->set_up_db_for_test;


=head1 DESCRIPTION

Spots::Test::DB::Init is a module with routines to set-up a pg
database for a particular test, allowing easy use of a schema
and/or data file that's either specifically tailored for a
particular test, or alternately a more general form shared by all
of the tests.

You're expected to have a set-up something like:

   t/
     01-a_test_file.t
     02-another_test.t
     03-still_another.t
   t/dat/
         spots_schema.sql  # pg_dump of db schema
         spots_data.sql    # pg_dump of db data (a minimal, restricted set)
         t02/
             spots_data.sql    # alternate version for the 02-*.t test
   t/out/

Normally, the *.sql files in the t/dat location are used, but
they can be overridden (in this example, for test 02-*.t) with an
alternate version in a test specific location (e.g. t/dat/t02
for the 02-*.t test).

With this system, you can write tests that create a new, uniquely named 
DATABASE on the fly setting it up with the given schema and data sets, 
so you can run your tests with a database in a known state.  

You can then optionally drop the db (relatively) safely-- the
system will refuse if certain conditions aren't met, e.g. by
default it refuses unless the database is named "*_test".

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

use Spots::DB::Init;
use Spots::DB::Init::Namer;
use Spots::DB::Handle;

use FindBin qw($Bin);

=item new

Creates a new Spots::Test::DB::Init object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );

{ no warnings 'once'; $DB::single = 1; }

# NN, a two digit number
has test_prefix         => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_test_prefix' );

has t_src_general_loc   => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_t_src_general_loc' );
has t_src_specific_loc  => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_t_src_specific_loc' );

# could also be called "t_out_specific_loc"
has out_loc             => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_out_loc' );

has dbnamer      => ( is => 'rw', isa => InstanceOf['Spots::DB::Init::Namer'], lazy => 1,
                      builder => sub{ Spots::DB::Init::Namer->new() } );

has dbname       => ( is => 'rw', isa => Str, lazy => 1,
                      builder => sub{ my $self =  shift;
                                      my $dbnamer = $self->dbnamer;
                                      my $uniq_dbname = $dbnamer->uniq_database_name();
                                      say "uniq_dbname: $uniq_dbname\n";
                                      return $uniq_dbname; } );
                                      
has db_init      => ( is => 'rw', isa => InstanceOf['Spots::DB::Init'], lazy => 1,
                      builder => 'builder_db_init');

has src_path     => ( is => 'rw', isa => ArrayRef, lazy => 1,
                      builder => 'builder_src_path');

has db_schema_file   => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_db_schema_file' );
has db_data_file     => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_db_data_file' );


=item builder_test_prefix

Extracts the two digit number from the prefix to the test file name.

=cut

sub builder_test_prefix {
  my $self = shift;
  my $file = $0;

  my $sans_path_pat =
    qr{ ( [^/]*? ) $ }x;

  my $prefix_pat =
    qr{ ^ ( [^\-]*? ) - }x;    

  my $prefix = '';
  if( $file =~ /$sans_path_pat/ ) {
    my $sanspath = $1;
    if( $sanspath =~ /$prefix_pat/ ) {
      if( length( $1 ) <= 4 ) { 
        $prefix = $1;
      }
    }
  }
  my $two_digit = sprintf( "%02d", $prefix );
  return $two_digit;
}



=item builder_t_src_general_loc

Path to the project-wide ("general") source files to be used by tests.

=cut

sub builder_t_src_general_loc {
  my $self = shift;
  my $t_src_general = "$Bin/src";
  mkpath( $t_src_general ) unless -d $t_src_general;
  return $t_src_general;
}


=item builder_t_src_specific_loc

Path to the test-specific source files for the current test. 
Files in this location take precedence over the general location.

=cut

sub builder_t_src_specific_loc {
  my $self = shift;
  my $t_src = $self->t_src_general_loc;
  my $test_prefix = $self->test_prefix;
  my $general_t_dat_loc = "$t_src/t" . $test_prefix;  # t/src/tNN
  mkpath( $general_t_dat_loc ) unless -d $general_t_dat_loc;
  return $general_t_dat_loc;
}

=item builder_out_loc

According to our naming convention, this might be called the "t_out_specific_loc", 
but we don't expect to use s "general" one, so we just call it the "out_loc".

=cut

sub builder_out_loc {
  my $self = shift;
  my $test_prefix = $self->test_prefix;
  my $out_loc = "$Bin/out/t" . $test_prefix;   # t/out/tNN
  mkpath( $out_loc ) unless -d $out_loc;
  return $out_loc;
}



=item builder_src_path

By default, the path will contain just two locations, 
one for all of the tests, the next specific to a particular *.t file.  
Typically that means 

  $Bin/dat/src
  $Bin/dat/src/tNN

Where "NN" is the numeric prefix from the name of a particular test file.

Optionally then, each test can have project-specific set-up files
that can over-ride the commonly used ones.  E.g. a typical test might
use the same schema as the other tests, but a specific data set.

=cut

sub builder_src_path {
  my $self = shift;
  my $general  = $self->t_src_general_loc;
  my $specific = $self->t_src_specific_loc;

  my @path = ( $general, $specific );
  return \@path;
}

=item builder_db_schema_file

=cut

sub builder_db_schema_file {
  my $self = shift;
  my $dbnamer = $self->dbnamer;
  my $prefix = $dbnamer->prefix;
  
  my $db_schema_file        = $prefix . "schema.sql";  # spots_schema.sql

  my $src_path = $self->src_path;
  my $full_db_schema_file = '';
 LOC:
  foreach my $loc ( reverse @{ $src_path } ) { 
    my $trial = "$loc/$db_schema_file";
    if (-e $trial ) {
      $full_db_schema_file = $trial;
      last LOC;
    }
  }
  return $full_db_schema_file;
}



=item builder_db_data_file

=cut

sub builder_db_data_file {
  my $self = shift;
  my $dbnamer = $self->dbnamer;
  my $prefix = $dbnamer->prefix;
  my $db_data_file       = $prefix . "data.sql"; # spots_data.sql
  my $src_path = $self->src_path;
  my $full_db_data_file = '';
 LOC:
  foreach my $loc ( reverse @{ $src_path } ) { 
    my $trial = "$loc/$db_data_file";
    if (-e $trial ) {
      $full_db_data_file = $trial;
      last LOC;
    }
  }
  return $full_db_data_file;
}


=item builder_db_init

=cut

sub builder_db_init {
  my $self = shift;

  my $out_loc   = $self->out_loc;   
  my $src_loc   = $self->t_src_general_loc;   # for lack of better, use the general (TODO needed?)

  # searches path (specific and general locations), names have full path
  my $db_schema_file = $self->db_schema_file;
  my $db_data_file   = $self->db_data_file;

  my $dbname = $self->dbname;
  my $sidb =
     Spots::DB::Init->new({    dbname             => $dbname,
                               live               => 0,  # Note: flipping it on below.
                               verbose            => 1,
                               debug              => 1,
                               unsafe             => 0,
                               log_loc            => "$out_loc",
                               backup_loc         => "$out_loc",

                               db_schema_loc      => "$src_loc",  # TODO needed?
                               db_schema_file     => "$db_schema_file",   # full path overrides above *_loc

                               db_data_loc        => "$src_loc",  # TODO needed?
                               db_data_file       => "$db_data_file",     # full path overrides above *_loc

                             # Guessing that these defaults are okay for now:
                             #  schema_backup_file => "$schema_backup_file", 
                             #  data_backup_file   => "$data_backup_file", 
                             #  pg_restore_file    => "$pg_restore_file", 
                             #  log_file           => "$log_file", 
                             });
  return $sidb;  # Spots::DB::Init object
}


=item set_up_db_for_test

Example usage:

  my $new_test_dbname = 
    $obj->set_up_db_for_test();

=cut

sub set_up_db_for_test {
  my $self = shift;
  my $sidb = $self->db_init;
  $sidb->live( 1 );

  $sidb->create_db;
  if( $self->check_for_schema_sql ) { 
    $sidb->load_schema;
    if( $self->check_for_data_sql ) { 
      $sidb->load_data;
    }
  }
  my $dbname = $self->dbname;
  return $dbname;
}



=item check_for_schema_sql

=cut

sub check_for_schema_sql {
  my $self = shift;
  my $db_schema_file = $self->db_schema_file;
  my $found;
  if( -e $db_schema_file ) {
    $found = 1;
  } else {
    $found = 0;
    carp( "Missing db init schema sql file: $db_schema_file" );
  }
  return $found;
}


=item check_for_data_sql

=cut

sub check_for_data_sql {
  my $self = shift;
  my $db_data_file = $self->db_data_file;
  my $found;
  if( -e $db_data_file ) {
    $found = 1;
  } else {
    $found = 0;
    carp( "Missing db init data sql file: $db_data_file" );
  }
  return $found;
}
 


=item check_for_setup_sql

=cut

sub check_for_setup_sql {
  my $self = shift;
  my $db_schema_file = $self->db_schema_file;
  my $db_data_file   = $self->db_data_file;

  my $schema_exists = ( -e $db_schema_file  );
  my $data_exists   = ( -e $db_data_file  );

  my $mess = '';
  unless( $schema_exists ) {
    $mess .= 'db_schema_file: $db_schema_file ';
  }
  unless( $data_exists ) {
    $mess .= 'db_data_file: $db_data_file ';
  }
  my $setup_okay = 0;
  if( $schema_exists && $data_exists ) {
    $setup_okay = 1;
  } else {
    $setup_okay = 0;
    carp( "Missing db init sql file(s): $mess" );
  }
  return $setup_okay;
}





=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
28 May 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
