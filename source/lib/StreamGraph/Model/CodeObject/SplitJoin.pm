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


sub getSplitCode {
	my $self = shift;
	my $splitCode = "split ";
	my $splitType = $self->split->{data}->splitType;
	if($splitType eq "void"){
		$splitCode .= "roundrobin(0)";
	} elsif($splitType eq "roundrobin") {
		$splitCode .= "(";
		my $graph = $self->split->{graph}->{graph}; 
		# self->codeObjects only has pipelines
		$splitCode .= join(", ", 
			map($graph->get_edge_attribute($self->split, $_->codeObjects->[0], 'data')->inputMult
				, @{$self->codeObjects}
			)
		);
		$splitCode .= ")";
	} else {
		$splitCode .= $splitType;
	}
	return $splitCode . ";\n";
}


sub getJoinCode{
	my $self = shift;
	my $joinCode = "join ";
	my $joinType = $self->join->{data}->joinType;
	if($joinType eq "void"){
		$joinCode .= "roundrobin(0)";
	} elsif($joinType eq "roundrobin") {
		$joinCode .= $joinType . "(";
		# self->codeObjects only has pipelines
		$joinCode .= join(", ", 
			map($_->codeObjects->[-1]->{graph}->get_edge_attribute($_->codeObjects->[-1], $self->join, 'data')->outputMult, 
				@{$self->codeObjects}
			)
		);
		$joinCode .= ")";
	} else {
		$joinCode .= $joinType;
	}
	return $joinCode . ";\n";
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
	$splitJoinCode .= "{\n\t" . $self->getSplitCode;
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
	$splitJoinCode .= "\t" . $self->getJoinCode . "}\n\n";
	$self->code($splitJoinCode);
	$self->{'_generated'} = 1;
}

sub buildCode {
	my $self = shift;
	my $pipelinesCode = shift;
	my $splitJoinesCode = shift;
	$splitJoinesCode .= $self->code;
	foreach my $codeObject (@{$self->codeObjects}) {
		($pipelinesCode, $splitJoinesCode) = $codeObject->buildCode($pipelinesCode, $splitJoinesCode);
	}
	return ($pipelinesCode, $splitJoinesCode);
}

1;