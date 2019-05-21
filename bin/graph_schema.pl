#!/usr/bin/env perl
#                                      2019/05/20 17:59:14

=head1 NAME

graph_schema.pl

=head1 SYNOPSIS


=head1 DESCRIPTION

Stub documentation for graph_schema.pl,
created by template.el.

It looks like the author of this script was negligent
enough to leave the stub unedited.

=cut

use 5.10.0;
use warnings;
use strict;
$|=1;
use Data::Dumper;

use FindBin qw($Bin);
use lib ("$Bin/../lib/");
use Spots::HomePage; 

# /home/doom/End/Cave/GraphVizDbiGeneral/Wall/GraphViz-DBI-General/lib/GraphViz/DBI/General.pm
# /home/doom/End/Cave/Spots/Wall/Spots/bin/graph_schema.pl
use lib "$Bin/../../../GraphVizDbiGeneral/Wall/GraphViz-DBI-General/lib";
use GraphViz::DBI::General;


my $base             = shift || "spots_schema";
my $runny = 'Nyrlathotep';
my $output_directory = shift || "/home/doom/End/Cave/Spots/Output/$runny"; 

my $diagram_file = "$output_directory/$base.png";

my $obj = Spots::HomePage->new(
                               output_basename  => $base,
                               output_directory => $output_directory,
                               db_database_name => 'spots',
                              );

my $dbh = $obj->dbh;

my $gbdh = GraphViz::DBI::General->new($dbh);
# TODO in SYNOPSIS: schema => set_*
$gbdh->set_schema('public');  # default used by Postgresql
$gbdh->set_catalog( undef );  

open my $fh, ">", $diagram_file or die "Couldn't open $diagram_file: $!";
$gbdh->graph_tables->as_png( $fh );


### This can't find a "new", but it should see the one from Graphviz::DBI, it does a use base of that.


__END__

=head1 AUTHOR

Joseph Brenner, E<lt>doom@fandango.obsidianrook.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
