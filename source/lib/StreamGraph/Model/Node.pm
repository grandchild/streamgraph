package StreamGraph::Model::Node;

use warnings;
use strict;

use Moo;
use YAML qw(Bless Blessed);

use StreamGraph::View::Item;


has name        => ( is=>"rw", default=>"item" );
# has view        => ( is=>"ro", required=>1 );
has x           => ( is=>"rw", default=>0 );
has y           => ( is=>"rw", default=>0 );

has saveMembers => ( is=>"ro", default=>sub{[qw(name x y outputType)]} );

sub yaml_dump {
	my $self = shift;
	Bless($self)->keys($self->saveMembers);
	return Blessed($self);
}




1;
