
use strict;

package Modware::Role::DataStash::Pub;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

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

=item find_or_import_pub_id (Int $pmid)

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
        my $pub_rs
            = $self->schema->resultset('Pub::Pub')
            ->search( { uniquename => $pmid },
            { select => [qw/uniquename title volume pubplace/] } );
        if ( $pub_rs->count > 0 ) {
            my $pub = $pub_rs->first;
            my $new_pub
                = $self->pg_schema->resultset('Pub::Pub')->find_or_create(
                {   uniquename => $pub->uniquename,
                    title      => $pub->title,
                    volume     => $pub->volume,
                    pubplace   => $pub->pubplace
                }
                );
            $self->set_pub_row( $pmid, $new_pub );
            return $self->get_pub_row($pmid)->pub_id;
        }
    }
}

__END__

=head1 NAME

Modware::Role::DataStash::Pub - Role for hash look-up of C<Pub::Pub>

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut
