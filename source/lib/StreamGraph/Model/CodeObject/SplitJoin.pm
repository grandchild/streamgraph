package StreamGraph::Model::CodeObject::SplitJoin;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use StreamGraph::Model::CodeObject::Pipeline;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;
use Data::Dump qw(dump);


has codeObjects	=> ( is=>"rw", default=>sub{()} );
has split		=> ( is=>"rw" );
has join		=> ( is=>"rw" );
has next		=> ( is=>"rw" );
has code 		=> ( is=>"rw" );
has parameters	=> ( is=>"rw", default=>sub{()} );
has inputType	=> ( is=>"rw" );


sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete $args{first};
	$args{split} = $node;
	my @codeObjects = ();
	my @successors = $node->successors;
	my @parameters = ();
	foreach my $s (@successors) {
		my $pipeline = StreamGraph::Model::CodeObject::Pipeline->new(first=>$s);
		push(@codeObjects, $pipeline);
		push(@parameters, @{$pipeline->parameters});
	}
	$args{next} = $codeObjects[0]->next;
	$args{join} = $args{next};
	$args{codeObjects} = \@codeObjects;
	@parameters = StreamGraph::Util::List::unique(@parameters);
	$args{parameters} = \@parameters;
	return \%args;
}


sub generate {
	my ($self) = @_;
	$self->name(StreamGraph::CodeGen::getTopologicalConstructName(0, $self->split->{data}->name));
	$self->inputType($self->split()->{data}->outputType);
	$self->outputType($self->join()->{data}->inputType);
	my $splitJoinCode = $self->inputType . "->" . $self->outputType . " splitjoin " . $self->name;
	if(@{$self->parameters}){
		$splitJoinCode .= "(" . join(", ", map($_->outputType . " " . $_->name, @{$self->parameters})) . ")";
	}
	$splitJoinCode .= "{\n\tsplit " . $self->split()->{data}->splitType . ";\n";
	foreach my $codeObject (@{$self->codeObjects}) {
		if(!($codeObject->{'_generated'})){
			$codeObject->generate();
		}
		$splitJoinCode .= "\tadd " . $codeObject->name;
		my @params = @{$codeObject->parameters};
		if(@params){
			$splitJoinCode .= "(" . join(", ", map($_->name, @params)) . ")";
		}
		$splitJoinCode .= ";\n";
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