package Spots::Herd;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::Herd - Spots::Herd manages Spots::Category objects

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::Herd;
   my $obj = Spots::Herd->new();
   my $all_cats = $obj->cats;    # aref of Category objects

=head1 DESCRIPTION

The Spots::Herd class handles objects of Spots::Category
(that is to say, it "herds cats"), in particular it has 
methods to generate an array of all the Category objects 
from the category table.

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
use Spots::Category;
use Spots::DB::Handle;

=item new

Creates a new Spots::Herd object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );
# Tempted to use Mouse over Moo so I can do my usual "isa => 'Int'"

{ no warnings 'once'; $DB::single = 1; }

has dbname    => (is => 'rw', isa => Str, default => 'spots' );

has dbh       => (is => 'rw', isa => InstanceOf['DBI::db'], lazy=>1,
                         builder => 'builder_db_connection' );

has cat_ids   => (is => 'rw', isa => ArrayRef, lazy=>1,
                         builder => 'builder_all_cat_ids' );

has cats      => (is => 'rw',
                  isa => ArrayRef[InstanceOf['Spots::Category']],
                  lazy=>1, builder => 'builder_all_cats' );

# optional list of cat ids to override the "all_cats" lookup-- 
# so you can use restricted sets for debugging purposes. 
has over_cats  => (is => 'rw', isa => ArrayRef[Int], lazy=>1,
                   default => sub{ [] } );



=item builder_all_cat_ids

=cut

sub builder_all_cat_ids {
  my $self = shift;

  my @over_cats = @{ $self->over_cats };
  my $dbh  = $self->dbh;

  my $sql;
  if( @over_cats ) {
    $sql = $self->generate_sql_for_some_cat_ids( \@over_cats );
  } else { # just get all cats for real
    $sql = $self->generate_sql_for_all_cat_ids;
  }

  my $sth = $dbh->prepare( $sql );
  $sth->execute();  
  my $cats = $sth->fetchall_arrayref;
  my @flat_cats = map{ $_->[0] } @{ $cats };
  return \@flat_cats;
}



=item builder_all_cats

=cut

sub builder_all_cats {
  my $self = shift;
  my $ids = $self->cat_ids;
  my @cats = map{ Spots::Category->new({id=>$_}) } @{ $ids };
  return \@cats;
}

# =item builder_db_connection

# =cut

# sub builder_db_connection {
#   my $self = shift;
#   # TODO break-out more of these params as object fields
#   # TODO add a secrets file to pull auth info from
#   my $dbname = $self->dbname; # default 'spots'
#   my $port = '5432';
#   my $data_source = "dbi:Pg:dbname=$dbname;port=$port;";
#   my $username = 'doom';
#   my $auth = '';
#   my %attr = (AutoCommit => 1, RaiseError => 1, PrintError => 0);
#   my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
#   return $dbh;
# }


=item builder_db_connection

=cut

sub builder_db_connection {
  my $self = shift;
  my $dbname = $self->dbname;   # default 'spots'
  my $obj = Spots::DB::Handle->new({ dbname => $dbname });
  my $dbh = $obj->dbh;
  return $dbh;
}

=item generate_sql_for_all_cat_ids

Query to return cat ids with associated spot counts.

This filters out cats without spots.

(( TODO Q: is this the right place to do this? ))

=cut

sub generate_sql_for_all_cat_ids {
  my $self = shift;
  my $sql =<<"__END_ALL_CAT_SKULL";
  SELECT category.id AS id, spotted_cats.cnt AS spot_count
    FROM 
     (SELECT category.id AS id, count(*) AS cnt
      FROM category
      JOIN spots ON (category.id = spots.category) 
      GROUP BY category.id
      HAVING count(*) > 0) AS spotted_cats,
     category,
     metacat
  WHERE 
     category.metacat = metacat.id  AND 
     category.id = spotted_cats.id
  ORDER BY
     metacat.sortcode, category.id
__END_ALL_CAT_SKULL
  return $sql;
}



=item generate_sql_for_all_cat_ids_nomcsort

Query to return cat ids with associated spot counts.

This filters out cats without spots.

(( TODO Q: is this the right place to do this? ))

=cut

sub generate_sql_for_all_cat_ids_nomcsort {
  my $self = shift;
  my $sql =<<"__END_ALL_CAT_SKULL_NOMCS";
      SELECT category.id AS id, count(*)
      FROM category JOIN spots ON (category.id = spots.category) 
      GROUP BY category.id
      HAVING count(*) > 0
__END_ALL_CAT_SKULL_NOMCS
  return $sql;
}


=item generate_sql_for_some_cat_ids

Variant of L<generate_sql_for_all_cat_ids> that uses the
over_cats list to restrict the set of cats we work on.

=cut

sub generate_sql_for_some_cat_ids {
  my $self      = shift;
  my $over_cats = shift || $self->over_cats;
  my $over_cat_str = join ',', @{ $over_cats };
  my $sql =<<"__END_SOME_CAT_SKULL";
      SELECT category.id AS id, count(*)
      FROM category JOIN spots ON (category.id = spots.category) 
      WHERE category.id IN ( $over_cat_str )
      GROUP BY category.id
      HAVING count(*) > 0
__END_SOME_CAT_SKULL
  return $sql;
}







# This might be used to create an array of Cats
# without a query for each id:
# then create each cat object with a pre-built cat_hash

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
24 May 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
