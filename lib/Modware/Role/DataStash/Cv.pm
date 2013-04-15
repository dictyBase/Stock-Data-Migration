
use strict;

package Modware::Role::DataStash::Cv;

use MooseX::Method::Signatures;
use Moose::Role;
use namespace::autoclean;

has '_cv_row' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => [qw/Hash/],
    default => sub { {} },
    handles => {
        set_cv_row => 'set',
        get_cv_row => 'get',
        has_cv_row => 'defined'
    }
);

method find_or_create_cv_id (Str $name) {
    if ( $self->has_cv_row($name) ) {
        return $self->get_cv_row($name)->cv_id;
    }
    my $row = $self->pg_schema->resultset('Cv::Cv')
        ->search( { name => $name }, { select => [qw/cv_id name/] } );
    if ( $row->count > 0 ) {
        $self->set_cv_row( $name, $row->first );
        return $self->get_cv_row($name)->cv_id;
    }
    else {
        my $new_cv
            = $self->pg_schema->resultset('Cv::Cv')
            ->create( { name => $name } );
        $self->set_cv_row( $name, $new_cv );
        return $self->get_cv_row($name)->cv_id;
    }
}

1;

__END__