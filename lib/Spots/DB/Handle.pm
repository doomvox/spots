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
      { dbname => 'spots_test' });
   my $dbh = $obj->dbh;

=head1 DESCRIPTION

Spots::DB::Handle is a module that is largely a wrapper around DBI connect
that supplies project-specific defaults which can be over-ridden, e.g. for
test purposes.

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

=item debug 

Turn on debug mode (currently unsused). And while under development, it's always on.

=item dbname 

The postgresql DATABASE name we're connecting to.   Defaults to "spots".

=item port

Defaults to 5432 (pg standard).

=item username

Defaults to $USER.

=item auth

Like a password.  Defaults to blank.

=item autocommit

Defaults to 1.

=item raise_error

Defaults to 1.

=item print_error

Defaults to 0.

=item dbh

Main access method, use to get the shared dbh handle to be used by the entire project.

=back 

=cut


{ no warnings 'once'; $DB::single = 1; }

has debug       => (is => 'rw', isa => Bool, default => sub{return ($DEBUG||0)});

has dbname      => (is => 'rw', isa => Str, default => 'spots' );  
has port        => (is => 'rw', isa => Str, default => '5432' );  
has username    => (is => 'rw', isa => Str, default => $USER );  
has auth        => (is => 'rw', isa => Str, default => '' );  

has autocommit  => (is => 'rw', isa => Bool, default => 1 );  
has raise_error => (is => 'rw', isa => Bool, default => 1 );  
has print_error => (is => 'rw', isa => Bool, default => 0 );  

has dbh         => (is => 'rw', isa => InstanceOf['DBI::db'], lazy => 1,
                    builder => 'builder_db_connection' );

=item builder_db_connection

Create a conncetion to the postgres database, returns a database filehandle.

=cut

sub builder_db_connection {
  my $self = shift;

  # TODO add a secrets file to pull auth info from?
  #      Can you just use .pgaccess for this?
  my $dbname = $self->dbname; # default 'spots'
  my $port = $self->port;  # '5432';
  my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
  my $username = $self->username;  # 'doom'
  my $auth = $self->auth;  # ''
  my %attr = ( AutoCommit => $self->autocommit,    # 1 
               RaiseError => $self->raise_error,   # 1 
               PrintError => $self->print_error ); # 0
  # my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
  state $dbh ||= DBI->connect($data_source, $username, $auth, \%attr);
  # state $count; say "builder_db_connection called " . $count++ . " times.";
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
