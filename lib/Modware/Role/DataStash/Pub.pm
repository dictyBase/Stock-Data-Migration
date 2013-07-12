
use strict;

package Modware::Role::DataStash::Pub;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

has '_publication' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_publication => 'set',
        get_publication => 'get',
        has_publication => 'defined'
    }
);

=item find_pubmed_id

=cut

method find_pubmed_id(Str $dbs_id) {
    if ( $self->has_publication($dbs_id) ) {
        return $self->get_publication($dbs_id)->pubmedid;
    }
    my $old_dbxref_id
        = $self->schema->resultset('General::Dbxref')
        ->search( { accession => $dbs_id },
        { select => [qw/dbxref_id accession/] } )->first->dbxref_id;
    my $strain_pub_rs
        = $self->legacy_schema->resultset('StockCenter')->search(
        { 'dbxref_id' => $old_dbxref_id },
        {   select => 'pubmedid',
            cache  => 1
        }
        );
    if ( $strain_pub_rs->count > 0 ) {
        $self->set_publication( $dbs_id, $strain_pub_rs->first );
        return $self->get_publication($dbs_id)->pubmedid;
    }
    else {
        print "Cannot find publication for $dbs_id\n";
        return 0;
    }
}

has '_pub_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_pub_row => 'set',
        get_pub_row => 'get',
        has_pub_row => 'defined'
    }
);

=item find_or_import_publication (Int $pmid)

=cut

method find_or_import_pub_id (Int $pmid) {
    if ( $self->has_pub_row($pmid) ) {
        return $self->get_pub_row($pmid)->pub_id;
    }
    my $row
        = $self->pg_schema->resultset('Pub::Pub')
        ->search( { uniquename => $pmid },
        { select => [qw/pub_id uniquename/], cache => 1 } );
    if ( $row->count > 0 ) {
        $self->set_pub_row( $pmid, $row->first );
        return $self->get_pub_row($pmid)->pub_id;
    }
    else {
        my $pub_rs = $self->schema->resultset('Pub::Pub')->search(
            { 'me.uniquename' => $pmid },
            {   join   => 'type',
                select => [
                    qw/me.uniquename me.title me.volume me.pubplace me.type_id/
                ]
            }
        );
        if ( $pub_rs->count > 0 ) {
            my $pub = $pub_rs->first;
            my $new_pub
                = $self->pg_schema->resultset('Pub::Pub')->find_or_create(
                {   uniquename => $pub->uniquename,
                    title      => $pub->title,
                    volume     => $pub->volume,
                    pubplace   => $pub->pubplace,
                    type_id    => $self->find_or_create_cvterm_id(
                        $pub->type->name, 'pub_type', 'Publication'
                    )
                }
                );
            $self->set_pub_row( $pmid, $new_pub );
            return $self->get_pub_row($pmid)->pub_id;
        }
    }
}

1;

__END__

=head1 NAME

Modware::Role::DataStash::Pub - Role for hash look-up of C<Pub::Pub>

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut
