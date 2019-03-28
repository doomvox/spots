#!/usr/bin/perl
#                                      2019/03/15 02:43:32

=head1 NAME

link_extractor.pl

=head1 SYNOPSIS

  link_extractor.pl /tmp/homepage.html > homepage_links.tsv

=head1 DESCRIPTION

Simple link extractor, gets list of labels and urls given a local
html filename (not a url).

=cut

use 5.10.0;
use warnings;
use strict;
$|=1;
use Data::Dumper;

# use HTML::TreeBuilder 5 -weak; # Ensure weak references in use
use WWW::Mechanize ();

my $file_name = shift || "/home/doom/End/Spots/mah_moz_ohm.html";

# my $tree = HTML::TreeBuilder->new; # empty tree
# $tree->parse_file($file_name);
# print "Hey, here's a dump of the parse tree of $file_name:\n";
# $tree->dump; # a method we inherit from HTML::Element

my $url = "file:///$file_name";

my $mech = WWW::Mechanize->new();
$mech->get( $url );
 
# $mech->_extract_links();
my @links = $mech->find_all_links();

# say Dumper( @links );

print "short_label\turl\n";
foreach my $l (@links) {

 my $url   = $l->url();
 my $label = $l->text();

# print "url: $url, label: $label\n";

 print "$label\t$url\n";
}



__END__

=head1 AUTHOR

Joseph Brenner, E<lt>doom@tangoE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
