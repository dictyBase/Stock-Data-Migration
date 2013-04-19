
use strict;

package Modware::Stock::Plasmid::Migrator;

use Moose;
use namespace::autoclean;

use Modware::Role::DataStash;
with 'Modware::Role::Command::WithBCS';

has 'data_stash' => (
    is      => 'rw',
    isa     => 'Modware::Role::DataStash',
    default => sub { return Modware::Role::DataStash->new },
    lazy    => 1
);

sub migrate_plasmid {
    my ($self) = @_;
    my $plasmid_rs
        = $self->legacy_schema->resultset('Plasmid')
        ->search( {}, { select => [qw/id name description pubmedid/] } );

    while ( my $plasmid = $plasmid_rs->next ) {
        my $dbp_id = sprintf( "DBP%07d", $plasmid->id );
        my $dbxref_id = $self->data_stash->find_or_create_dbxref_id($dbp_id);
        my $type_id = $self->data_stash->find_or_create_cvterm_id('plasmid');
        my $organism_id = $self->data_stash->find_or_create_organism_id(
            'Dictyostelium discoideum');

        my $new_plasmid_stock
            = $self->pg_schema->resultset('Stock::Stock')->find_or_create(
            {   dbxref_id   => $dbxref_id,
                organism_id => $organism_id,
                name        => $plasmid->name,
                uniquename  => $dbp_id,
                description => $plasmid->description,
                type_id     => $type_id
            }
            );

        print $new_plasmid_stock->dbxref_id . "\t"
            . $new_plasmid_stock->organism_id . "\t"
            . $new_plasmid_stock->type_id . "\t"
            . $new_plasmid_stock->name . "\t"
            . $new_plasmid_stock->uniquename . "\n";
    }
}

1;

__END__
