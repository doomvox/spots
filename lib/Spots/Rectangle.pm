package Spots::Rectangle;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Spots::Rectangle - The great new Spots::Rectangle! TODO revise this

=head1 VERSION

Version 0.01

=cut

# TODO revise these before shipping
our $VERSION = '0.01';
my $DEBUG = 1;

=head1 SYNOPSIS

   use Spots::Rectangle;
   my $obj = Spots::Rectangle->new({ ...  });

   # TODO expand on this

=head1 DESCRIPTION

Spots::Rectangle is a module that ...

TODO expand this stub documentation, which was created by perlnow.el.

=head1 METHODS

=over

=cut

use 5.10.0;
use Carp;
use Data::Dumper;

=item new

Creates a new Spots::Rectangle object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes. These attributes are:

=over

=item <TODO fill-in attributes here... most likely, sort in order of utility>

=back

=cut

# Example attribute:
# has is_loop => ( is => 'rw', isa => Int, default => 0 );
# Tempted to use Mouse over Moo so I can do my usual "isa => 'Int'"

{ no warnings 'once';
   $DB::single = 1;
}

### Fill in additional methods here
### hint: perlnow-insert-method




=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
07 Apr 2019

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

No warranty is provided with this code.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
