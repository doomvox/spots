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
use Spots::DB::Namer;
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

has test_prefix  => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_test_prefix' );
has data_loc     => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_data_loc' );
has src_loc      => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_src_loc' );
has out_loc      => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_out_loc' );

has dbnamer      => ( is => 'rw', isa => InstanceOf['Spots::DB::Namer'], lazy => 1,
                      builder => sub{ Spots::DB::Namer->new() } );

has dbname       => ( is => 'ro', isa => Str, lazy => 1,
                      builder => sub{ my $self =  shift;
                                      my $dbnamer = $self->dbnamer;
                                      my $uniq_dbname = $dbnamer->uniq_database_name();
                                      say "uniq_dbname: $uniq_dbname\n";
                                      return $uniq_dbname; } );
                                      
has db_init      => ( is => 'rw', isa => InstanceOf['Spots::DB::Init'], lazy => 1,
                      builder => 'builder_db_init');

has src_path     => ( is => 'rw', isa => ArrayRef, lazy => 1,
                      builder => 'builder_src_path');

has schema_file   => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_schema_file' );
has data_file     => ( is => 'rw', isa => Str, lazy => 1, builder => 'builder_data_file' );


=item builder_test_prefix

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
  return $prefix;
}



=item builder_data_loc

=cut

sub builder_data_loc {
  my $self = shift;
  my $test_prefix = sprintf( "%02d", $self->test_prefix);
  my $dat_loc = "$Bin/dat/t" . $test_prefix;
  mkpath( $dat_loc ) unless -d $dat_loc;
  return $dat_loc;
}

=item builder_src_loc

=cut

sub builder_src_loc {
  my $self = shift;
  my $data_loc = $self->data_loc;
  my $src_loc = "$data_loc/src";
  mkpath( $src_loc ) unless -d $src_loc;
  return $src_loc;
}



=item builder_out_loc

=cut

sub builder_out_loc {
  my $self = shift;
  my $data_loc = $self->data_loc;
  my $out_loc = "$data_loc/out";
  mkpath( $out_loc ) unless -d $out_loc;
  return $out_loc;
}



=item builder_src_path

By default, the path will contain just two locations, 
one for all of the tests, the next specific to a particular *.t file.  
Typically that means 

  $Bin/dat/src
  $Bin/dat/tNN/src

Where "NN" is the numeric prefix from the name of a particular test file.

Optionally then, each test can have project-specific set-up files
that can over-ride the commonly used ones.  E.g. a typical test might
use the same schema as the other tests, but a specific data set.

=cut

# TODO this feature may be redundant with the src_loc settings, and so on.
#      clarify the situation, then look for crufty features to remove.
sub builder_src_path {
  my $self = shift;
  my $test_prefix = $self->test_prefix;
  my $data_loc = $self->data_loc;

  my $general  = "$data_loc/src";
  my $specific = "$data_loc/$test_prefix/src";

  my @path = ( $general, $specific );
  return \@path;
}

=item builder_schema_file

=cut

sub builder_schema_file {
  my $self = shift;
  my $dbnamer = $self->dbnamer;
  my $prefix = $dbnamer->prefix;
  
  my $schema_file        = $prefix . "schema.sql";  # spots_schema.sql

  my $src_path = $self->src_path;
  my $full_schema_file = '';
 LOC:
  foreach my $loc ( reverse @{ $src_path } ) { 
    my $trial = "$loc/$schema_file";
    if (-e $trial ) {
      $full_schema_file = $trial;
      last LOC;
    }
  }
  return $full_schema_file;
}



=item builder_data_file

=cut

sub builder_data_file {
  my $self = shift;
  my $dbnamer = $self->dbnamer;
  my $prefix = $dbnamer->prefix;
  my $db_data_file       = $prefix . "data.sql"; # spots_data.sql

  my $src_path = $self->src_path;
  my $full_data_file = '';
 LOC:
  foreach my $loc ( reverse @{ $src_path } ) { 
    my $trial = "$loc/$db_data_file";
    if (-e $trial ) {
      $full_data_file = $trial;
      last LOC;
    }
  }
  return $full_data_file;
}


=item builder_db_init

=cut

sub builder_db_init {
  my $self = shift;
  my $data_file = $self->data_file;
  my $out_loc   = $self->out_loc;
  my $src_loc   = $self->src_loc;

  # searches path (specific and general locations), names have full path
  my $schema_file = $self->schema_file;

  my $dbname = $self->dbname;
  my $sidb =
     Spots::DB::Init->new({    dbname             => $dbname,
                               live               => 0,  # Note: flipping it on below.
                               verbose            => 1,
                               debug              => 1,
                               unsafe             => 0,
                               log_loc            => "$out_loc",
                               backup_loc         => "$out_loc",
                               schema_loc         => "$src_loc", 
                               data_loc           => "$src_loc", 

                               schema_file        => "$schema_file",   # full path okay to override *_loc?
                               db_data_file       => "$data_file", 

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

  if( $self->check_for_schema_sql ) { 
    $sidb->create_db;
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
  my $schema_file = $self->schema_file;
  my $found;
  if( -e $schema_file ) {
    $found = 1;
  } else {
    $found = 0;
    carp( "Missing db init schema sql file: $schema_file" );
  }
  return $found;
}


=item check_for_data_sql

=cut

sub check_for_data_sql {
  my $self = shift;
  my $data_file = $self->data_file;
  my $found;
  if( -e $data_file ) {
    $found = 1;
  } else {
    $found = 0;
    carp( "Missing db init data sql file: $data_file" );
  }
  return $found;
}



=item check_for_setup_sql

=cut

sub check_for_setup_sql {
  my $self = shift;
  my $schema_file = $self->schema_file;
  my $data_file   = $self->data_file;

  my $schema_exists = ( -e $schema_file  );
  my $data_exists   = ( -e $data_file  );

  my $mess = '';
  unless( $schema_exists ) {
    $mess .= 'schema_file: $schema_file ';
  }
  unless( $data_exists ) {
    $mess .= 'data_file: $data_file ';
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
