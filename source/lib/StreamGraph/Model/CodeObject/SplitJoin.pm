package StreamGraph::Model::CodeObject::SplitJoin;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use StreamGraph::Model::CodeObject::Pipeline;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;
use StreamGraph::Util qw(unique);
use Data::Dump qw(dump);


has codeObjects	=> ( is=>"rw", default=>sub{()} );
has split		=> ( is=>"rw" );
has join		=> ( is=>"rw" );
has next		=> ( is=>"rw" );
has code 		=> ( is=>"rw" );
has parameters	=> ( is=>"rw", default=>sub{()} );
has inputType	=> ( is=>"rw" );
has graph		=> ( is=>"rw" );

sub BUILDARGS {
	my ($class, %args) = @_;
	my $node = delete $args{first};
	$args{split} = $node;
	my $graph = $args{graph};
	my @codeObjects = ();
	my @successors = $graph->successors($node);
	my @parameters = ();
	foreach my $s (@successors) {
		my $pipeline = StreamGraph::Model::CodeObject::Pipeline->new(first=>$s, graph=>$graph);
		push(@codeObjects, $pipeline);
		push(@parameters, @{$pipeline->parameters});
	}
	$args{next} = $codeObjects[0]->next;
	$args{join} = $args{next};
	$args{codeObjects} = \@codeObjects;
	@parameters = unique(@parameters);
	$args{parameters} = \@parameters;
	return \%args;
}


sub getSplitCode {
	my $self = shift;
	my $view = shift;
	my $splitCode = "split ";
	my $splitType = $self->split->splitType;
	if($splitType eq "void"){
		$splitCode .= "roundrobin(0)";
	} elsif($splitType eq "roundrobin") {
		$splitCode .= "$splitType("; 
		# self->codeObjects only has pipelines
		my $first = 1;
		foreach my $cO (@{$self->codeObjects}) {
			if(defined($self->split->get_edge_data_to($cO->codeObjects->[0], $self->graph))){
				if(!$first){
					$splitCode .= ", ";
				}
				$first = 0;
				$splitCode .= $self->split->get_edge_data_to($cO->codeObjects->[0], $self->graph)->inputMult;
			} else {
				$view->println("Connection from " . $self->split->name . " to " . 
					$cO->codeObjects->[0]->name . " does not exist or has no data", 'dialog-error');
				return "ERROR";
			}
		}
		$splitCode .= ")";
	} else {
		$splitCode .= $splitType;
	}
	return $splitCode . ";\n";
}


sub getJoinCode{
	my $self = shift;
	my $view = shift;
	my $joinCode = "join ";
	my $joinType = $self->join->joinType;
	if($joinType eq "void"){
		$joinCode .= "roundrobin(0)";
	} elsif($joinType eq "roundrobin") {
		$joinCode .= $joinType . "(";
		# self->codeObjects only has pipelines
		my $first = 1;
		foreach my $cO (@{$self->codeObjects}) {
			if(defined($cO->codeObjects->[-1]->get_edge_data_to($self->join, $self->graph))){
				if(!$first) {
					$joinCode .= ", ";
				}
				$first = 0;
				$joinCode .= $cO->codeObjects->[-1]->get_edge_data_to($self->join, $self->graph)->outputMult;
			} else {
				$view->println("Connection from " . $cO->codeObjects->[-1]->name . " to " . 
					$self->join->name . " does not exist or has no data", 'dialog-error');
				return "ERROR";
			}
		}
		$joinCode .= ")";
	} else {
		$joinCode .= $joinType;
	}
	return $joinCode . ";\n";
}


sub generate {
	my ($self, $view) = @_;
	$self->name(StreamGraph::CodeGen::getTopologicalConstructName(0, $self->split->name));
	$self->inputType($self->split()->outputType);
	$self->outputType($self->join()->inputType);
	my $splitJoinCode = $self->inputType . "->" . $self->outputType . " splitjoin " . $self->name;
	if(@{$self->parameters}){
		$splitJoinCode .= "(" . join(", ", map($_->outputType . " " . $_->name, @{$self->parameters})) . ")";
	}
	my $tmpCode = $self->getSplitCode($view);
	if($tmpCode eq "ERROR"){
		return "ERROR";
	}
	$splitJoinCode .= "{\n\t" . $tmpCode;
	foreach my $codeObject (@{$self->codeObjects}) {
		if(!($codeObject->{'_generated'})){
			if($codeObject->generate($view) eq "ERROR"){
				return "ERROR";
			}
		}
		$splitJoinCode .= "\tadd " . $codeObject->name;
		my @params = @{$codeObject->parameters};
		if(@params){
			$splitJoinCode .= "(" . join(", ", map($_->name, @params)) . ")";
		}
		$splitJoinCode .= ";\n";
	}
	$tmpCode = $self->getJoinCode($view);
	if($tmpCode eq "ERROR"){
		return "ERROR";
	}
	$splitJoinCode .= "\t" . $tmpCode . "}\n\n";
	$self->code($splitJoinCode);
	$self->{'_generated'} = 1;
	return 1;
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