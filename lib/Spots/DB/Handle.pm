package Spots::DB::Handle;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::DB::Handle - db handle for spots

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::DB::Handle;
   my $obj = Spots::DB::Handle->new(
      { 
        dbname => 'spots_test'  
       });

   my $dbh = $obj->dbh;

                                   

=head1 DESCRIPTION

Spots::DB::Handle is a module that is largely a wrapper around DBI connect
that supplies project-specific defaults which can be over-ridden, 
e.g. for test purposes.


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
use String::ShellQuote qw( shell_quote_best_effort );
use DBI;

=item new

Creates a new Spots::DB::Handle object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );

{ no warnings 'once'; $DB::single = 1; }

has debug => (is => 'rw', isa => Bool, default => sub{return ($DEBUG||0)});

has dbname => (is => 'rw', isa => Str, default => 'spots' );  

has port => (is => 'rw', isa => Str, default => '5432' );  

has username => (is => 'rw', isa => Str, default => $USER );  

has auth  => (is => 'rw', isa => Str, default => '' );  

has autocommit  => (is => 'rw', isa => Bool, default => 1 );  
has raise_error => (is => 'rw', isa => Bool, default => 1 );  
has print_error => (is => 'rw', isa => Bool, default => 0 );  

has dbh => (is => 'rw', isa => InstanceOf['DBI::db'], lazy => 1,
            builder => 'builder_db_connection' );

=item builder_db_connection

Create a conncetion to the postgres database, returns a database filehandle.

=cut

sub builder_db_connection {
  my $self = shift;

  # TODO add a secrets file to pull auth info from--
  #      but understand .pgaccess first
  my $dbname = $self->dbname; # default 'spots'
  # my $port = '5432';
  my $port = $self->port;
  my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
  # my $username = 'doom';
  my $username = $self->username;
  # my $auth = '';
  my $auth = $self->auth;
  # my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
  my %attr = (AutoCommit => $self->autocommit,
              RaiseError => $self->raise_error,
              PrintError => $self->print_error );
  my $dbh = DBI->connect($data_source, $username, $auth, \%attr);

  return $dbh;
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
