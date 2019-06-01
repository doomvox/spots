package Spots::DB::Init::Namer;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::DB::Namer - generate names for DATABASEs inside a pg database

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::DB::Namer;
   my $obj = Spots::DB::Namer->new();

   my $existing_databases = $dbnamer->list_databases;

   my $new_dbname =  $self->uniq_database_name;

=head1 DESCRIPTION

Spots::DB::Namer is a module to assist with tasks such as choosing 
a new, unique name for a DATABASE inside your postgresql database.

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



=item new

Creates a new Spots::DB::Namer object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );

has list_databases_cmd => ( is => 'rw', isa => Str, default => 'psql -l' );

has prefix => ( is => 'rw', isa => Str, default => 'spots_' );
has suffix => ( is => 'rw', isa => Str, default => '_test' );

# set-up once and cache, to avoid minor race condition at midnight
has yyyy_month_dd => ( is => 'ro', isa => Str, builder => 'builder_yyyy_month_dd' );

{ no warnings 'once'; $DB::single = 1; }

=item builder_yyyy_month_dd

Returns the current date in a form like:

   2019may22 

=cut

sub builder_yyyy_month_dd {
  my $self = shift;
  my $time = shift || time;
  my ($mday, $mon, $year) = ( localtime( $time ) )[3..5];
  $year += 1900;
  my @mon = qw(jan feb mar apr may jun jul aug sep oct nov dec);
  my $stamp = $year . $mon[ $mon ] . $mday;
  return $stamp;
}

=item list_databases

=cut

sub list_databases {
  my $self = shift;

  my $list_db_cmd = $self->list_databases_cmd;
  my @dbs_dbox =   qx{ $list_db_cmd };
  chomp( @dbs_dbox );
  # say Dumper( \@dbs_dbox );

  my @dbs;
  for (my $i=3; $i <= ($#dbs_dbox - 2); $i++) {
    my $line = $dbs_dbox[ $i ];
    my @pieces = split( m{ \| }, $line, 2 );
    my $db = $pieces[0];
    $db =~ s{^ \s+}{}x;
    $db =~ s{\s+$}{}x;
    push @dbs, $db unless $db =~ /^\s*$/
  }
  # say Dumper( \@dbs );
  return \@dbs;
}

=item uniq_database_name

Returns a name that is not in use as a postgresql DATABASE, 
by default in a form suitable for some aspects of the "Spots" 
project, following the pattern:
  
  prefix + hostname + pid + hhmmss [ + char ] + suffix

That might be something like:

  spots_fandango_21464_141256_test

But if that name were in use already for some reason, 
this could would begin checking alternate names such as:

  spots_fandango_21449_141232_A_test
  spots_fandango_21449_141232_B_test
  spots_fandango_21449_141232_C_test

=cut

sub uniq_database_name {
  my $self = shift;
  my $prefix = shift || $self->prefix;
  my $suffix = shift || $self->suffix;
  my $dbs = $self->list_databases;
  chomp(
        my $hostname = qx{ hostname }
        );
  my @time  = localtime( time );
  my ($sec, $min, $hour) = @time[0,1,2];
  my $hhmmss = "$hour$min$sec";
  my $expanded_prefix = $prefix . $hostname . '_' . $$ . '_' . $hhmmss;
  my $dbname = $expanded_prefix . $suffix;
  my $char = chr(64);
  while ( any{ $_ eq $dbname } @{ $dbs } ) {
    $char = chr( ord( $char ) + 1 ); # first time, 'A'
    $dbname = $expanded_prefix . '_' . $char . $suffix;
  } 
  return $dbname;
}



=item db_exists

Example usage:

   if( $obj->db_exists( $dbname ) { 
      # do something with $dbname
   }

=cut

sub db_exists {
  my $self = shift;
  my $dbname = shift || $self->dbname;
  my $dbs = $self->list_databases;
  my $retval;
  if ( any{ $_ eq $dbname } @{ $dbs } ) {
    $retval = 1;
  } else {
    $retval = 0;
  }
  return $retval;
}






=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
27 May 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
