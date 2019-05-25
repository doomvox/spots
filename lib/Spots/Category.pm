package Spots::Category;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::Category - The great new Spots::Category! TODO revise this

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::Category;
   my $cat = Spots::Category->new({ id => $cat_id });

   my $cat_name = $cat->name;
   my $spots = $cat->spots;
   my $spot_count = $cat->spot_count;

   my $height =  $cat->height;
   my $width  =  $cat->width;

=head1 DESCRIPTION

Spots::Category is a module that handles the data describing a
"category" of links.

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
use String::ShellQuote qw( shell_quote_best_effort );
use DBI;

=item new

Creates a new Spots::Category object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

{ no warnings 'once'; $DB::single = 1; }

has id        => (is => 'rw', isa => Int, required=>1 );  

has x_scale   => (is => 'rw', isa => Num, default=>12 );  # average px per char
has y_scale   => (is => 'rw', isa => Num, default=>1.3 ); # rem per line

has debug     => (is => 'rw', isa => Bool, default => sub{return ($DEBUG||0)});

has spots      => (is => 'ro', isa => ArrayRef, lazy=>1, builder => 'builder_spots');

has spot_count => (is => 'rw', isa => Int,      lazy=>1, builder => 'builder_spot_count');  

# cat_hash container: has builders to access, pop from db, but might be set by a Herd.
#         metacat.sortcode  AS metacat_sortcode,
#         metacat.name      AS metacat_name, 
#         metacat.id        AS metacat_id,
#         category.name     AS name

has cat_hash     => (is => 'rw', isa => HashRef,  lazy=>1, builder => 'builder_cat_hash' );   

has name         => (is => 'rw', isa => Str,      lazy=>1,
                      builder => sub{ return ${ $_[0]->cat_hash }{ name } } );   

has metacat_id   => (is => 'rw', isa => Int,      lazy=>1,
                      builder => sub{ return ${ $_[0]->cat_hash }{ metacat_id } } );   

has metacat_name => (is => 'rw', isa => Str,      lazy=>1,
                      builder => sub{ return ${ $_[0]->cat_hash }{ metacat_name } } );   

has metacat_sortcode => (is => 'rw', isa => Str,      lazy=>1,
                      builder => sub{ return ${ $_[0]->cat_hash }{ metacat_sortcode } } );   

has height  => (is => 'ro', isa => Num,  lazy=>1, builder => 'builder_height' );   # rem (from spot_count)
has width   => (is => 'ro', isa => Int,  lazy=>1, builder => 'builder_width' );    # px  (from spot labels)


has db_dbname => (is => 'rw', isa => Str, default => 'spots' );

has dbh       => (is => 'rw', isa => InstanceOf['DBI::db'], lazy=>1,
                         builder => 'builder_db_connection' );

has sth_spots => (is => 'rw', isa => InstanceOf['DBI::st'], lazy=>1,
                         builder => 'builder_prep_sth_sql_spots');

has sth_cat   => (is => 'rw', isa => InstanceOf['DBI::st'], lazy=>1,
                         builder => 'builder_prep_sth_sql_cat');

=item builder_spots

Returns an aref of hrefs about this cat's spots:

Each row has fields:

  spots_id
  url
  label
  metacat_id

=cut

sub builder_spots  {
  my $self = shift;
  my $cat_id = $self->id;
  my $sth_spots = $self->sth_spots;
  $sth_spots->execute( $cat_id );
  my $cat_spot_lines = $sth_spots->fetchall_arrayref({}); 
  return $cat_spot_lines;
}

=item builder_spot_count

=cut

sub builder_spot_count {
  my $self = shift;
  my $cat_spots = $self->spots;
  my $spot_count = scalar( @{ $cat_spots } );      
  return $spot_count;
}

=item builder_cat_hash

Returns an href about this cat, with the fields

        metacat.sortcode  AS metacat_sortcode,
        metacat.name      AS metacat_name, 
        metacat.id        AS metacat_id,
        category.name     AS name

=cut

sub builder_cat_hash  {
  my $self = shift;
  my $cat_id = $self->id;
  my $sth_cat = $self->sth_cat;
  $sth_cat->execute( $cat_id );
  my $cat_hash = $sth_cat->fetchrow_hashref(); 
  return( $cat_hash );
}



=item builder_width

Example usage:

    my $width_in_chars = $self->builder_width();

=cut

sub builder_width {
  my $self = shift;
  my $cat_spots = $self->spots;
  my $scaling_factor = $self->x_scale;
  my $max_chars = 0;
  # for each link line in a cat rectpara
  foreach my $spot ( @{ $cat_spots } ) {
    my $label   =  $spot->{ label };
    my $chars = length( $label );
    if ( $chars > $max_chars ) {
      $max_chars = $chars;
    }
  }
  my $width = $max_chars * $scaling_factor;
  return $width;
}


=item builder_height

=cut

sub builder_height {
  my $self = shift;
  my $spot_count = $self->spot_count;
  my $scaling_factor = $self->y_scale;
  my $height = $spot_count * $scaling_factor;
  return $height;
}


=item builder_db_connection

=cut

sub builder_db_connection {
  my $self = shift;
  # TODO break-out more of these params as object fields
  # TODO add a secrets file to pull auth info from
  my $dbname = $self->db_dbname; # default 'spots'
  my $port = '5432';
  my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
  my $username = 'doom';
  my $auth = '';
  my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
  my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
  return $dbh;
}

=item builder_prep_sth_sql_spots

=cut

sub builder_prep_sth_sql_spots {
  my $self = shift;
  my $dbh = $self->dbh;
  my $sql_spots = $self->sql_for_spots();
  my $sth_spots = $dbh->prepare( $sql_spots );
  return $sth_spots;
}


=item builder_prep_sth_sql_cat

=cut

sub builder_prep_sth_sql_cat {
  my $self = shift;
  my $dbh = $self->dbh;
  my $sql_cat = $self->sql_for_cat();
  my $sth_cat = $dbh->prepare( $sql_cat );
  return $sth_cat;
}


=back

=head2 sql 

=over 

=item sql_for_spots

SQL to get label and url information for a given category.id.

=cut

sub sql_for_spots {
  my $self = shift;
  my $sql_spots =<<"__END_SKULL_SPOTS";
    SELECT spots.id AS id, url, label, category.metacat AS metacat
    FROM spots JOIN category ON (category.id = spots.category) 
    WHERE category.id = ?
__END_SKULL_SPOTS
  return $sql_spots;
}



=item sql_for_cat

The sql to use given a category.id to get basic info from that
category row, also including the metacat name from the metacat table.

=cut

sub sql_for_cat {
  my $self = shift;
  my $sql_cat =<<"__END_CAT_SKULL";
      SELECT
        metacat.sortcode  AS metacat_sortcode,
        metacat.name      AS metacat_name, 
        metacat.id        AS metacat_id,
        category.name     AS name
      FROM
        metacat, category
      WHERE
        category.metacat = metacat.id AND
        category.id = ? 
__END_CAT_SKULL
  return $sql_cat;
}




# This might be used by Herd class, to create array of Cats:

#       SELECT
#         metacat.sortcode  AS mc_ord,
#         metacat.name      AS mc_name, 
#         metacat.id        AS metacat,
#         category.id       AS id,
#         category.name     AS name,
#         count(*)          AS cnt
#       FROM
#         metacat, category, spots
#       WHERE
#         spots.category = category.id AND
#         category.metacat = metacat.id 
#       GROUP BY 
#         metacat.sortcode,
#         metacat.name,
#         metacat.id,
#         category.id,
#         category.name
#       ORDER BY 
#         metacat.sortcode,
#         metacat.name,
#         metacat.id,
#         category.id,
#         category.name;








=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
23 May 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
