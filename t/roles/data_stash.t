
use Test::Moose;
use Test::Spec;

BEGIN { require_ok('Modware::Role::DataStash'); }

describe 'A DataStash instance' => sub {
    my $stash;
    before all => sub {
        $stash = Modware::Role::DataStash->new;
    };
    it 'should consume roles' => sub {
        does_ok( $stash, 'Modware::Role::DataStash::' . $_ )
            for qw/Cv Cvterm Db Dbxref Organism StrainInventory/;
    };
};
runtests unless caller;
