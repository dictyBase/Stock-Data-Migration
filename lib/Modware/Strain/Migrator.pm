
use strict;

package Modware::Strain::Migrator;

use JSON;
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

=item migrate_strain()

=cut

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

=item migrate_strain_inventory()

=cut

sub migrate_strain_inventory {
    my ($self) = @_;
    if ( $self->data_stash->is_strain_invent_loaded ) {
        my $strain_rs = $self->pg_schema->resultset('Stock::Stock')->search(
            {},
            {   select => [qw/stock_id uniquename/],
                cache  => 1,

                #rows   => 500
            }
        );
        while ( my $strain = $strain_rs->next ) {
            my $strain_invent_rs
                = $self->data_stash->find_strain_inventory(
                $strain->uniquename );

            my $stockcollection_new
                = $self->data_stash->find_or_create_stockcollection(
                'dicty stock center');

            if ($strain_invent_rs) {
                if ( $strain_invent_rs->count > 0 ) {
                    my $rank = 0;
                    while ( my $strain_invent = $strain_invent_rs->next ) {

                        my $inventory = {
                            'location' => $strain_invent->location,
                            'color'    => $strain_invent
                                ->color,    # if $strain_invent->color ne '\''
                            'number of vials' => $strain_invent->no_of_vials,
                            'storage date'    => $strain_invent->storage_date,
                            'obtained as'     => $strain_invent->obtained_as
                            ,    # $strain_invent->obtained_as !~ /\?/
                            'stored as' => $strain_invent->stored_as,
                        };

                        my $json_text = JSON->new->pretty->encode($inventory);

                        $strain->create_related(
                            'stockprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'strain_inventory'),
                                value => $json_text,
                                rank  => $rank
                            }
                        );

                        $rank += 1;

                    }

                    $stockcollection_new->create_related(
                        'stockcollection_stocks',
                        { stock_id => $strain->stock_id } );
                }
            }
        }
    }
    else {
        print "Please load the strain_inventory ontology first !\n";
    }
}

1;

__END__

=head1 NAME

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut
