
use strict;

package Modware::Role::DataStash::Cvterm;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

has '_cvterm_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_cvterm_row => 'set',
        get_cvterm_row => 'get',
        has_cvterm_row => 'defined'
    }
);

=item find_or_create_cvterm_id (Str $name)

=cut

method find_or_create_cvterm_id (Str $name, Str $cv_name, Str $db_name) {                                                                    
    $self->_find_or_create_cvterm_for_stock($name)
        if ( $name =~ m/strain|plasmid/ );
    if ( $self->has_cvterm_row($name) ) {
        return $self->get_cvterm_row($name)->cvterm_id;
    }
    my $cvterm_row = $self->pg_schema->resultset('Cv::Cvterm')
        ->search( { name => $name }, { select => [qw/cvterm_id name/] } );
    if ( $cvterm_row->count > 0 ) {
        $self->set_cvterm_row( $name, $cvterm_row->first );
        return $self->get_cvterm_row($name)->cvterm_id;
    }
    else {
        my $new_cvterm = $self->pg_schema->resultset('Cv::Cvterm')->create(
            {   name  => $name,
                cv_id => $self->find_or_create_cv_id($cv_name),
                dbxref_id =>
                    $self->find_or_create_dbxref_id( $name, $db_name )
            }
        );
		$self->set_cvterm_row($name, $new_cvterm);
		return $self->get_cvterm_row($name)->cvterm_id;
    }
}

=item _find_or_create_cvterm_for_stock (Str $name)

=cut

method _find_or_create_cvterm_for_stock (Str $name, Str $cv_name, Str $db_name) {
    if ( $self->has_cvterm_row($name) ) {
        return $self->get_cvterm_row($name)->cvterm_id;
    }
    my $row = $self->pg_schema->resultset('Cv::Cvterm')
        ->search( { name => $name }, { select => [qw/cvterm_id name/] } );
    if ( $row->count > 0 ) {
        $self->set_cvterm_row( $name, $row->first );
        return $self->get_cvterm_row($name)->cvterm_id;
    }
    else {
        my $new_cvterm = $self->pg_schema->resultset('Cv::Cvterm')->create(
            {   name  => $name,
                cv_id => $self->find_or_create_cv_id($cv_name),
                dbxref_id =>
                    $self->find_or_create_dbxref_id( $name, $db_name )
            }
        );
        $self->set_cvterm_row( $name, $new_cvterm );
        return $self->get_cvterm_row($name)->cvterm_id;
    }
}

1;

__END__

=head1 NAME

Modware::Role::DataStash::Cvterm - Role for hash look-up of C<Cv::Cvterm>

=head1 DESCRIPTION

=head1 SYNOPSIS

=cut

