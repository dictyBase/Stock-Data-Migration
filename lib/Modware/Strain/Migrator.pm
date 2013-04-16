
use strict;

package Modware::Strain::Migrator;

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

sub migrate_strain {

    my ($self) = @_;
    my $strain_rs = $self->legacy_schema->resultset('StockCenter')->search(
        {},
        {   select => [qw/strain_name species strain_description dbxref_id/],
            cache  => 1,
            rows   => 500
        }
    );

    while ( my $strain = $strain_rs->next ) {
        my $dbs_id
            = $self->data_stash->find_dbxref_accession( $strain->dbxref_id );
        my $dbxref_id = $self->data_stash->find_or_create_dbxref_id($dbs_id);
        my $organism_id
            = $self->data_stash->find_or_create_organism_id(
            $strain->species );
        my $type_id = $self->data_stash->find_or_create_cvterm_id('strain');

        my $new_strain_stock
            = $self->pg_schema->resultset('Stock::Stock')->find_or_create(
            {   dbxref_id   => $dbxref_id,
                organism_id => $organism_id,
                name        => $strain->strain_name,
                uniquename  => $dbs_id,
                description => $strain->strain_description,
                type_id     => $type_id
            }
            );

        print $new_strain_stock->dbxref_id . "\t"
            . $new_strain_stock->organism_id . "\t"
            . $new_strain_stock->name . "\t"
            . $new_strain_stock->uniquename . "\t"
            . $new_strain_stock->type_id . "\n";
    }
}

sub migrate_strain_inventory {
    my ($self) = @_;
    if ( $self->data_stash->is_strain_invent_loaded ) {
        my $strain_rs = $self->pg_schema->resultset('Stock::Stock')->search(
            {},
            {   select => [qw/stock_id uniquename/],
                cache  => 1,
                rows   => 500
            }
        );
        while ( my $strain = $strain_rs->next ) {
            my $strain_invent_rs
                = $self->data_stash->find_strain_inventory(
                $strain->uniquename );

            if ($strain_invent_rs) {
                if ( $strain_invent_rs->count > 0 ) {
                    my $rank = 0;
                    my $stockcollection_id;
                    while ( my $strain_invent = $strain_invent_rs->next ) {

                        my $stockcollection_new
                            = $self->data_stash
                            ->find_or_create_stockcollection(
                            $strain->uniquename );
                        $stockcollection_id
                            = $stockcollection_new->stockcollection_id;
                        $stockcollection_new->create_related(
                            'stockcollectionprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'location'),
                                value => $strain_invent->location,
                                rank  => $rank
                            }
                        ) if $strain_invent->location;

                        $stockcollection_new->create_related(
                            'stockcollectionprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'color'),
                                value => $strain_invent->color,
                                rank  => $rank
                            }
                        ) if $strain_invent->color ne '\'';

                        $stockcollection_new->create_related(
                            'stockcollectionprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'storage date'),
                                value => $strain_invent->storage_date,
                                rank  => $rank
                            }
                        );

                        $stockcollection_new->create_related(
                            'stockcollectionprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'number of vials'),
                                value => $strain_invent->no_of_vials,
                                rank  => $rank
                            }
                        ) if $strain_invent->no_of_vials;

                        $stockcollection_new->create_related(
                            'stockcollectionprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'obtained as'),
                                value => $strain_invent->obtained_as,
                                rank  => $rank
                            }
                            )
                            if $strain_invent->obtained_as
                            and $strain_invent->obtained_as !~ /\?/;

                        $stockcollection_new->create_related(
                            'stockcollectionprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'stored as'),
                                value => $strain_invent->stored_as,
                                rank  => $rank
                            }
                        ) if $strain_invent->stored_as;

         #                        print $strain->uniquename . "\t";
         #                        print $strain_invent->no_of_vials . "\t"
         #                            if $strain_invent->no_of_vials
         #                            and $strain_invent->no_of_vials !~ /na/;
         #                        print $strain_invent->location . "\t"
         #                            if $strain_invent->location;
         #                        print $strain_invent->color . "\t"
         #                            if $strain_invent->color ne '\'';
         #                        print $strain_invent->storage_date . "\t"
         #                            if $strain_invent->storage_date;
         #                        print $strain_invent->obtained_as . "\t"
         #                            if $strain_invent->obtained_as
         #                            and $strain_invent->obtained_as !~ /\?/;
         #                        print $strain_invent->stored_as . "\t"
         #                            if $strain_invent->stored_as
         #                            and $strain_invent->stored_as ne "?";
         #
         #                        print "\n";
                        $rank += 1;
                    }
                    $strain->create_related( 'stockcollection_stocks',
                        { stockcollection_id => $stockcollection_id } );
                }
            }
        }
    }
    else {
        print "Please load the strain_inventory ontology first !\n";
    }
}

1;
