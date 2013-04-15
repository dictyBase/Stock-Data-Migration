use strict;

package Modware::Role::DataStash::Organism;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

has '_organism_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_organism_row => 'set',
        get_organism_row => 'get',
        has_organism_row => 'defined'
    }
);

method find_or_create_organism_id (Str $genus_species) {
    my @organism = split( / /, $genus_species );
    if ( $self->has_organism_row( $organism[1] ) ) {
        return $self->get_organism_row( $organism[1] )->organism_id;
    }
    my $row
        = $self->pg_schema->resultset('Organism::Organism')
        ->search( { species => $organism[1] },
        { select => [qw/organism_id species/] } );
    if ( $row->count > 0 ) {
        $self->set_organism_row( $organism[1], $row->first );
        return $self->get_organism_row( $organism[1] )->organism_id;
    }
    else {
        my $new_organism_row
            = $self->pg_schema->resultset('Organism::Organism')
            ->create(
            {   genus        => $organism[0],
                species      => $organism[1],
                common_name  => $organism[1],
                abbreviation => substr( $organism[0], 0, 1 ) . "."
                    . $organism[1]
            }
            );
        $self->set_organism_row( $organism[1], $new_organism_row );
        return $self->get_organism_row( $organism[1] )->organism_id;
    }
}

1;

__END__