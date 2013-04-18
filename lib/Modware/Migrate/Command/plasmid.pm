
use strict;

package Modware::Migrate::Command::plasmid;

use Moose;
use Moose::Util qw/ensure_all_roles/;
use namespace::autoclean;

use Modware::Stock::Plasmid::Migrator;
extends qw/Modware::Migrate::Chado/;
with 'Modware::Role::Command::WithBCS';

sub execute {
    my ($self) = @_;

    my $migrator = Modware::Stock::Plasmid::Migrator->new;

    my $guard = $self->pg_schema->storage->txn_scope_guard;
    $migrator->migrate_plasmid();
    $guard->commit;

}

1;

__END__

=head1 NAME

Modware::Migrate::Command::strain - Migrate stock_center data from legacy schema to standard chado

=cut
