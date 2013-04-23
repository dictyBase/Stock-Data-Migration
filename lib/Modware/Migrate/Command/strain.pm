
use strict;

package Modware::Migrate::Command::strain;

use Moose;
use Moose::Util qw/ensure_all_roles/;
use namespace::autoclean;

use Modware::Strain::Migrator;
extends qw/Modware::Migrate::Chado/;
with 'Modware::Role::Command::WithBCS';

sub execute {
    my ($self) = @_;

    my $migrator = Modware::Strain::Migrator->new;

    my $guard = $self->pg_schema->storage->txn_scope_guard;

    #$migrator->migrate_strain();
    #$migrator->migrate_strain_inventory();
    $migrator->migrate_strain_pub();
    $guard->commit;

}

1;

__END__

=head1 NAME

Modware::Migrate::Command::strain - Migrate stock_center data from legacy schema to standard chado

=cut
