
use strict;

package Modware::Role::DataStash;

use Moose;

with 'Modware::Role::DataStash::Cv';
with 'Modware::Role::DataStash::Cvterm';
with 'Modware::Role::DataStash::Db';
with 'Modware::Role::DataStash::Dbxref';
with 'Modware::Role::DataStash::Organism';
with 'Modware::Role::DataStash::Pub';
with 'Modware::Role::DataStash::StrainInventory';

with 'Modware::Role::Command::WithBCS';

1;

__END__

=head1 NAME

Modware::Role::DataStash - Class consuming all hash look-up roles

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut
