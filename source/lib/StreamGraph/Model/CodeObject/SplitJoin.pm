package StreamGraph::Model::CodeObject::SplitJoin;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use StreamGraph::Model::CodeObject::Pipeline;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;


has split  => ( is=>"rw" );
has join   => ( is=>"rw" );


sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete $args{first};
	$args{split} = $node;
	my @codeObjects = [];
	my @successors = $node->successors;
	foreach my $s (@successors) {
		push(@codeObjects, StreamGraph::Model::CodeObject::Pipeline->new(first=>$s));
	}
	# potentially check discrepancies here!
	$args{join} = $codeObjects[0]->next;
	return \%args;
}


sub generate {
	my ($self) = @_;
	$self->name(StreamGraph::CodeGen::getTopologicalConstructName(0, 1));
	my $codeObjects = $self->codeObjects();
	if ($codeObjects->[0]->isa("StreamGraph::Model::Node::Filter")) {
	 	$self->inputType($codeObjects->[0]->{data}->{inputType});
	} else {
		$codeObjects->[0]->generate();
		$self->inputType($codeObjects->[0]->inputType);
	}
	my @codeObjects = $codeObjects;
	if($codeObjects->[$#codeObjects]->isa("StreamGraph::Model::Node::Filter")){
		$self->outputType($codeObjects->[$#codeObjects]->{data}->{outputType});
	} else {
		$codeObjects->[$#codeObjects]->generate();
		$self->outputType($codeObjects->[$#codeObjects]->outputType);
	}
	my $splitJoinCode = $self->inputType . "->" . $self->outputType . " splitjoin " . $self->name . "{\n";
}

sub buildCode {
	my $self = shift;
	my ($pipelinesCode, $splitJoinesCode) = shift;
	$splitJoinesCode .= $self->code;
	foreach my $codeObject ($self->codeObjects) {
		# in a splitJoin the codeObjects can only be Pipelines (for the moment)
		if($codeObject->isa("StreamGraph::Model::CodeObject::Pipeline")){
			($pipelinesCode, $splitJoinesCode) = $codeObject->buildCode($pipelinesCode, $splitJoinesCode);
		}
	}
	return ($pipelinesCode, $splitJoinesCode);
}

1;