
use strict;

package Modware::Strain::Migrator;

use MooseX::Method::Signatures;
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
                    while ( my $strain_invent = $strain_invent_rs->next ) {

                        $strain->create_related(
                            'stockprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'location'),
                                value => $strain_invent->location,
                                rank  => $rank
                            }
                        ) if $strain_invent->location;

                        $strain->create_related(
                            'stockprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'color'),
                                value => $strain_invent->color,
                                rank  => $rank
                            }
                        ) if $strain_invent->color ne '\'';

                        $strain->create_related(
                            'stockprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'storage date'),
                                value => $strain_invent->storage_date,
                                rank  => $rank
                            }
                        );

                        $strain->create_related(
                            'stockprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'number of vials'),
                                value => $strain_invent->no_of_vials,
                                rank  => $rank
                            }
                        ) if $strain_invent->no_of_vials;

                        $strain->create_related(
                            'stockprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'obtained as'),
                                value => $strain_invent->obtained_as,
                                rank  => $rank
                            }
                            )
                            if $strain_invent->obtained_as
                            and $strain_invent->obtained_as !~ /\?/;

                        $strain->create_related(
                            'stockprops',
                            {   type_id => $self->data_stash
                                    ->find_or_create_cvterm_id(
                                    'stored as'),
                                value => $strain_invent->stored_as,
                                rank  => $rank
                            }
                        ) if $strain_invent->stored_as;

                        $rank += 1;

                    }
                }
            }
        }
    }
    else {
        print "Please load the strain_inventory ontology first !\n";
    }
}

sub migrate_strain_pub {
    my ($self) = @_;
    my $strain_rs = $self->pg_schema->resultset('Stock::Stock')->search(
        {},
        {   select => [qw/stock_id uniquename/],
            cache  => 1,
            rows   => 500
        }
    );
    while ( my $strain = $strain_rs->next ) {
        my $pmid = $self->data_stash->find_pubmed_id( $strain->uniquename );
        if ($pmid) {
            my @pmids = split( /,/, $pmid ) if $pmid =~ /,/;
            if (@pmids) {

                #print scalar(@pmids) . "\n";
                foreach my $pmid_ (@pmids) {
                    $pmid_ = $self->trim($pmid_);
                    my $pub_id
                        = $self->data_stash->find_or_import_pub_id($pmid_);
                    $strain->create_related( 'stock_pubs',
                        { pub_id => $pub_id } )
                        if $pub_id;
                    print $strain->uniquename . "\t"
                        . $pmid_ . "\t"
                        . $pub_id . "\n";
                }
            }
            else {
                my $pub_id = $self->data_stash->find_or_import_pub_id($pmid);
                $strain->create_related( 'stock_pubs', { pub_id => $pub_id } )
                    if $pub_id;
                print $strain->uniquename . "\t" . $pmid . "\t" . $pub_id
                    . "\n";
            }
        }
    }
}

method trim(Str $s) {
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

1;
