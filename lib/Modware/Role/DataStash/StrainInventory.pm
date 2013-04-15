
use strict;

package Modware::Role::DataStash::StrainInventory;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

has '_strain_invent_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_strain_invent_row => 'set',
        get_strain_invent_row => 'get',
        has_strain_invent     => 'defined'
    }
);

method find_strain_inventory(Str $dbs_id) {
    if ( $self->has_strain_invent($dbs_id) ) {
        return $self->get_strain_invent_row($dbs_id);
    }
    my $old_dbxref_id
        = $self->schema->resultset('General::Dbxref')
        ->search( { accession => $dbs_id },
        { select => [qw/dbxref_id accession/] } )->first->dbxref_id;
    my $strain_invent_rs
        = $self->legacy_schema->resultset('StockCenterInventory')->search(
        { 'strain.dbxref_id' => $old_dbxref_id },
        {   join   => 'strain',
            select => [
                qw/me.location me.color me.no_of_vials me.obtained_as me.stored_as me.storage_date/
            ],
            cache => 1
        }
        );
    if ( $strain_invent_rs->count > 0 ) {
        $self->set_strain_invent_row( $dbs_id, $strain_invent_rs );
        return $self->get_strain_invent_row($dbs_id);
    }
    else {
        print "Cannot find strain inventory for $dbs_id\n";
		return 0;
    }
}

method create_stockcollection (Str $dbs_id) {
    my $uniquename;
    my $stockcollection_rs
        = $self->pg_schema->resultset('Stock::Stockcollection')
        ->search( { uniquename => { like => $dbs_id . "%" } },
        { select => 'uniquename' } );
    if ( $stockcollection_rs->count == 0 ) {
        $uniquename = $dbs_id;
    }
    elsif ( $stockcollection_rs->count == 1 ) {
        $uniquename = $dbs_id . "|1";
    }
    elsif ( $stockcollection_rs->count >= 2 ) {
        my @ranks;
        while ( my $stockC = $stockcollection_rs->next ) {
            my @count = split( /\|/, $stockC->uniquename )
                if $stockC->uniquename =~ /\|/;
            push( @ranks, $count[1] ) if $count[1];
        }
        my @sorted_ranks = sort { $a <=> $b } @ranks;
        my $new_rank = $sorted_ranks[ scalar(@sorted_ranks) - 1 ] + 1;
        $uniquename = $dbs_id . "|" . $new_rank;
    }
    my $new_stockcollection_rs
        = $self->pg_schema->resultset('Stock::Stockcollection')->create(
        {   type_id    => $self->find_or_create_cvterm_id('strain_inventory'),
            name       => 'dictyBase stock center',
            uniquename => $uniquename
        }
        );
    return $new_stockcollection_rs;

}

method is_strain_invent_loaded () {
    my $cv_rs = $self->pg_schema->resultset('Cv::Cv')
        ->search( { name => 'strain_inventory' }, { rows => 1, cache => 1 } );
    return 1 if $cv_rs->count > 0;
}

1;

__END__
97:	To see 1 non-critical warnings rerun with -w
