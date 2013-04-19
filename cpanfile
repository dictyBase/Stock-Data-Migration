requires 'Moose', 2.0604;
requires 'MooseX::App::Cmd';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Method::Signatures';

requires 'Bio::Chado::Schema';
requires 'Math::Base36';

requires 'DBD::Pg';
requires 'DBD::Oracle';

on 'test' => sub {
	requires 'Test::Spec', '0.46';
};
