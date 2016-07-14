package StreamGraph::Model::CodeObject::SplitJoin;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use StreamGraph::Model::CodeObject::Pipeline;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;
use Data::Dump qw(dump);


has split  => ( is=>"rw" );
has join   => ( is=>"rw" );


sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete $args{first};
	$args{split} = $node;
	my @codeObjects = ();
	my @successors = $node->successors;
	foreach my $s (@successors) {
		push(@codeObjects, StreamGraph::Model::CodeObject::Pipeline->new(first=>$s));
	}
	$args{next} = $codeObjects[0]->next;
	$args{join} = $args{next};
	$args{codeObjects} = \@codeObjects;
	return \%args;
}


sub generate {
	my ($self) = @_;
	$self->name(StreamGraph::CodeGen::getTopologicalConstructName(0, $self->split->{data}->name));
	$self->inputType($self->split()->{data}->outputType);
	$self->outputType($self->join()->{data}->inputType);
	my $splitJoinCode = $self->inputType . "->" . $self->outputType . " splitjoin " . $self->name . "{\n";
	$splitJoinCode .= "\tsplit " . $self->split()->{data}->splitType . ";\n";
	foreach my $codeObject (@{$self->codeObjects}) {
		if(!($codeObject->{'_generated'})){
			$codeObject->generate();
		}
		$splitJoinCode .= "\tadd " . $codeObject->name . ";\n";
	}
	$splitJoinCode .= "\tjoin " . $self->join()->{data}->joinType . ";\n}\n\n";
	$self->code($splitJoinCode);
	$self->{'_generated'} = 1;
}

sub buildCode {
	my $self = shift;
	my $pipelinesCode = shift;
	my $splitJoinesCode = shift;
	$splitJoinesCode .= $self->code;
	foreach my $codeObject (@{$self->codeObjects}) {
		# in a splitJoin the codeObjects can only be Pipelines (for the moment)
		if($codeObject->isa("StreamGraph::Model::CodeObject::Pipeline")){
			($pipelinesCode, $splitJoinesCode) = $codeObject->buildCode($pipelinesCode, $splitJoinesCode);
		}
	}
	return ($pipelinesCode, $splitJoinesCode);
}

1;