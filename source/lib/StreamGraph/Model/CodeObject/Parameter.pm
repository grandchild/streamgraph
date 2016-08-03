package StreamGraph::Model::CodeObject::Parameter;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use Data::Dump qw(dump);

has associatedParameter	=> ( is=>"rw" );
has value				=> ( is=>"rw" );

sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete $args{node};
	$node->{'_generated'} = 1;
	$args{associatedParameter} = $node;
	$args{outputType} = $node->outputType;
	$args{value} = $node->value;
	$args{name} = $node->name;
	return \%args;
}


sub updateValues {
	my $self = shift;
	if(!defined($self)){
		return;
	}
	$self->name($self->associatedParameter->name);
	$self->value($self->associatedParameter->value);
	$self->outputType($self->associatedParameter->outputType);
}
1;