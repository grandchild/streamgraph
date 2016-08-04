package StreamGraph::Model::Saveable;

use strict;
use warnings;


use Moo;
use YAML qw(Bless Blessed);


has saveMembers => ( is=>"ro", default=>sub{[qw()]} );


sub yaml_dump {
	my $self = shift;
	Bless($self)->keys($self->saveMembers);
	return Blessed($self);
}

1;
