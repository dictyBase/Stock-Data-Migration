
use strict;

package Modware::Role::DataStash::Db;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

has '_db_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_db_row => 'set',
        get_db_row => 'get',
        has_db_row => 'defined'
    }
);

=item find_or_create_db_id (Str $name)
	
=cut

method find_or_create_db_id (Str $name) {
    if ( $self->has_db_row($name) ) {
        return $self->get_db_row($name)->db_id;
    }
    my $row
        = $self->pg_schema->resultset('General::Db')
        ->search( { name => $name }, { select => [qw/db_id name/] } );
    if ( $row->count > 0 ) {
        $self->set_db_row( $name, $row->first );
        return $self->get_db_row($name)->db_id;
    }
    else {
        my $new_db_row
            = $self->pg_schema->resultset('General::Db')
            ->create( { name => $name, } );
        $self->set_db_row( $name, $new_db_row );
        return $self->get_db_row($name)->db_id;
    }
}

1;

__END__

=head1 NAME

Modware::Role::DataStash::Db - Role for hash look-up of C<General::Db>

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut
