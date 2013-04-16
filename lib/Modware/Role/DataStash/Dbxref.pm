
use strict;

package Modware::Role::DataStash::Dbxref;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

has '_dbxref_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_dbxref_row    => 'set',
        get_dbxref_row    => 'get',
        delete_dbxref_row => 'delete',
        has_dbxref_row    => 'defined'
    }
);

=item find_dbxref_accession (Int $dbxref_id)
	
=cut

method find_dbxref_accession (Int $dbxref_id) {
    if ( $self->has_dbxref_row($dbxref_id) ) {
        return $self->get_dbxref_row($dbxref_id)->accession;
    }
    my $row
        = $self->schema->resultset('General::Dbxref')
        ->search( { dbxref_id => $dbxref_id },
        { select => [qw/dbxref_id accession/] } );
    if ( $row->count > 0 ) {
        $self->set_dbxref_row( $dbxref_id, $row->first );
        return $self->get_dbxref_row($dbxref_id)->accession;
    }
}

has '_dbxref_id_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_dbxref_id_row => 'set',
        get_dbxref_id_row => 'get',
        has_dbxref_id_row => 'defined'
    }
);

=item find_or_create_dbxref_id (Str $accession)

=cut

method find_or_create_dbxref_id (Str $accession) {
    if ( $self->has_dbxref_id_row($accession) ) {
        return $self->get_dbxref_id_row($accession)->dbxref_id;
    }
    my $row
        = $self->pg_schema->resultset('General::Dbxref')
        ->search( { accession => $accession },
        { select => [qw/dbxref_id accession/] } );
    if ( $row->count > 0 ) {
        $self->set_dbxref_id_row( $accession, $row->first );
        return $self->get_dbxref_id_row($accession)->dbxref_id;
    }
    else {
        my $new_dbxref_id
            = $self->pg_schema->resultset('General::Dbxref')->create(
            {   accession => $accession,
                db_id     => $self->find_or_create_db_id('dictyBase')
            }
            );
        $self->set_dbxref_id_row( $accession, $new_dbxref_id );
        return $self->get_dbxref_id_row($accession)->dbxref_id;
    }
}

1;

__END__

=head1 NAME

Modware::Role::DataStash::Dbxref - Role for hash look-up of C<General::Dbxref> data

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut