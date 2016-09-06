package StreamGraph::Model::CodeObject::Pipeline;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use StreamGraph::Model::CodeObject::SplitJoin;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;
use StreamGraph::Util qw(unique);
use Data::Dump qw(dump);

has codeObjects	=> ( is=>"rw", default=>sub{()} );
has next		=> ( is=>"rw" );
has code 		=> ( is=>"rw" );
has parameters	=> ( is=>"rw", default=>sub{()} );
has inputType	=> ( is=>"rw" );
has graph		=> ( is=>"rw" );


sub BUILDARGS {
	my ($class, %args) = @_;
	my $node = delete $args{first};
	my $first = $node;
	my $graph = $args{graph};
	my @codeObjects = ($node);
	my @successors = $graph->successors($node);
	my @parameters = @{$node->get_parameters($graph)};
	while ($successors[0] && !($successors[0]->is_join($graph))) {
		if($node->is_split($graph)) {
			my $splitjoin = StreamGraph::Model::CodeObject::SplitJoin->new(first=>$node, graph=>$graph);
			push(@codeObjects, $splitjoin);
			push(@codeObjects, $splitjoin->next);
			push(@parameters, @{$splitjoin->parameters});
			push(@parameters, @{$splitjoin->next->get_parameters($graph)});
			$node = $splitjoin->next;
		} else {
			push(@codeObjects, $successors[0]);
			my @p = @{$successors[0]->get_parameters($graph)};
			push(@parameters, @p);
			$node = $successors[0];
		}
		@successors = $graph->successors($node);
	}
	$args{next} = $successors[0];
	$args{codeObjects} = \@codeObjects;
	@parameters = unique(@parameters);
	$args{parameters} = \@parameters;
	return \%args;
}

# generates the code for the pipeline in the Pipeline Object
sub generate {
	my ($self, $view, $mainFlag) = @_;
	if(!$mainFlag || $mainFlag != 1){
		$mainFlag = 0;
	}
	$self->name(StreamGraph::CodeGen::getTopologicalConstructName($mainFlag));
	# CodeObjects list has all members of pipline in correct order. 
	# CodeObjects may be splitJoin constructs or filters
	my $codeObjects = $self->codeObjects();
	if ($codeObjects->[0]->isFilter) {
	 	$self->inputType($codeObjects->[0]->{inputType});
	} else {
		if( $codeObjects->[0]->generate($view) eq "ERROR"){
			return "ERROR";
		}
		$self->inputType($codeObjects->[0]->inputType);
	}
	my @codeObjects = $codeObjects;
	if($codeObjects->[-1]->isFilter){
		$self->outputType($codeObjects->[-1]->{outputType});
	} else {
		if( $codeObjects->[-1]->generate($view) eq "ERROR"){
			return "ERROR";
		}
		$self->outputType($codeObjects->[-1]->outputType);
	}
	my $pipelineHeader = $self->inputType . "->" . $self->outputType . " pipeline " . $self->name;
	# only generate so far because parameters need to be added  
	my $pipelineMembers = "";
	my @pipelineParameters = ();
	foreach my $codeObject (@{$codeObjects}) {
		if($codeObject->isa("StreamGraph::Model::CodeObject::SplitJoin")){
			# generate code for split join if it is not already generated
			if(!($codeObject->{'_generated'})){
				if($codeObject->generate($view) eq "ERROR"){
					return "ERROR";
				}
			}
			$pipelineMembers .= "\tadd " . $codeObject->name;
			my @params = @{$codeObject->parameters};
			if(@params){
				$pipelineMembers .= "(" . join(", ", map($_->name, @params)) . ")";
			}
			$pipelineMembers .= ";\n";
		} else {
			# element is Filter
			if($codeObject->isFilter && !($codeObject->{'_no_add'})){
				# get Parameters of Filter
				$pipelineMembers .= "\tadd " . $codeObject->{'_gen_name'} . StreamGraph::CodeGen::generateParameters($codeObject->get_parameters($self->graph, 0), 0, 1, 0, 0) . ";\n";
			}
		}
	}
	$pipelineMembers .= "}\n\n";
	# delete duplicates in pipelineParameters
	if($mainFlag){
		if(@{$self->parameters}){
			my $parametersText = join(";\n", map($_->outputType . " " . $_->name . " = " . $_->value, @{$self->parameters}));
			$pipelineHeader .= "{\n" . StreamGraph::CodeGen::generateCommentary("parameters as pipeline variables") . $parametersText;
			$pipelineHeader =~ s/\n/\n\t/g;
			$pipelineHeader .= ";";
		} else {
			$pipelineHeader .= "{";
		}
		$pipelineHeader .= "\n\t" . StreamGraph::CodeGen::generateCommentary("pipeline members");
	} else {
		if(@{$self->parameters}){
			$pipelineHeader .= "(" . join(", ", map($_->outputType . " " . $_->name, @{$self->parameters})) . ")";
		}
		$pipelineHeader .= "{\n";
	}
	$self->{'_generated'} = 1;
	$self->code($pipelineHeader . $pipelineMembers);
	return 1;
}

sub buildCode {
	my $self = shift;
	my $pipelinesCode = shift;
	my $splitJoinesCode = shift;
	$pipelinesCode .= $self->code;
	foreach my $codeObject (@{$self->codeObjects}) {
		if($codeObject->isa("StreamGraph::Model::CodeObject::SplitJoin")){
			($pipelinesCode, $splitJoinesCode) = $codeObject->buildCode($pipelinesCode, $splitJoinesCode);
		}
	}
	return ($pipelinesCode, $splitJoinesCode);
}

1;