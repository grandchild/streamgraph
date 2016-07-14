package StreamGraph::Model::CodeObject::Pipeline;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use StreamGraph::Model::CodeObject::SplitJoin;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;
use Data::Dump qw(dump);


sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete $args{first};
	my @codeObjects = ($node);
	my @successors = $node->successors;
	while ($successors[0] && !($successors[0]->is_join())) {
		if($node->is_split()) {
			my $splitjoin = StreamGraph::Model::CodeObject::SplitJoin->new(first=>$node);
			push(@codeObjects, $splitjoin);
			push(@codeObjects, $splitjoin->next);
			$node = $splitjoin->next;
		} else {
			push(@codeObjects, $successors[0]);
			$node = $successors[0];
		}
		@successors = $node->successors;
	}
	$args{next} = $successors[0];
	$args{codeObjects} = \@codeObjects;
	return \%args;
}

# generates the code for the pipeline in the Pipeline Object
sub generate {
	my ($self, $mainFlag) = @_;
	if(!$mainFlag || $mainFlag != 1){
		$mainFlag = 0;
	}
	$self->name(StreamGraph::CodeGen::getTopologicalConstructName($mainFlag));
	# CodeObjects list has all members of pipline in correct order. 
	# CodeObjects may be splitJoin constructs or filters
	my $codeObjects = $self->codeObjects();
	if ($codeObjects->[0]->isFilter) {
	 	$self->inputType($codeObjects->[0]->{data}->{inputType});
	} else {
		$codeObjects->[0]->generate();
		$self->inputType($codeObjects->[0]->inputType);
	}
	my @codeObjects = $codeObjects;
	if($codeObjects->[-1]->isFilter){
		$self->outputType($codeObjects->[-1]->{data}->{outputType});
	} else {
		$codeObjects->[-1]->generate();
		$self->outputType($codeObjects->[-1]->outputType);
	}
	my $pipelineHeader = $self->inputType . "->" . $self->outputType . " pipeline " . $self->name . "{\n";
	# only generate so far because parameters need to be added  
	my $pipelineMembers = "";
	my @pipelineParameters = ();
	foreach my $codeObject (@{$codeObjects}) {
		if($codeObject->isa("StreamGraph::Model::CodeObject::SplitJoin")){
			# generate code for split join if it is not already generated
			if(!($codeObject->{'_generated'})){
				$codeObject->generate();
			}
			$pipelineMembers .= "\tadd " . $codeObject->name . ";\n";
		} else {
			# element is Filter
			if($codeObject->isFilter){
				# get Parameters of Filter
				my @predecessors = StreamGraph::View::Item::predecessors($codeObject);
				my @filterParameters = @{StreamGraph::Util::List::filterNodesForType(\@predecessors, "StreamGraph::Model::Node::Parameter")};
				$pipelineMembers .= "\tadd " . $codeObject->{data}->{'_gen_name'} . StreamGraph::CodeGen::generateParameters(\@filterParameters, 0, 1, 0, 0) . ";\n";
				my @generatedParameters = @{StreamGraph::CodeGen::generateParameters(\@filterParameters, 1, 0, 1, 1)};
				if(@generatedParameters != 0){
					# merge
					push(@pipelineParameters, @generatedParameters);
				}
			}
		}
	}
	$pipelineMembers .= "}\n";
	# delete duplicates in pipelineParameters
	@pipelineParameters = StreamGraph::Util::List::unique(@pipelineParameters);
	my $pipelineParametersLength = @pipelineParameters;
	if(@pipelineParameters && ($pipelineParametersLength != 0)){
		$pipelineHeader .= StreamGraph::CodeGen::generateCommentary("parameters as pipeline variables") . join(";\n", @pipelineParameters);
		$pipelineHeader =~ s/\n/\n\t/g;
		$pipelineHeader .= ";\n\t" . StreamGraph::CodeGen::generateCommentary("pipeline members");
	}
	$self->{'_generated'} = 1;
	$self->code($pipelineHeader . $pipelineMembers);
	return;
}

sub buildCode {
	my $self = shift;
	my ($pipelinesCode, $splitJoinesCode) = shift;
	$pipelinesCode .= $self->code;
	foreach my $codeObject (@{$self->codeObjects}) {
		if($codeObject->isa("StreamGraph::Model::CodeObject::SplitJoin")){
			($pipelinesCode, $splitJoinesCode) = $codeObject->buildCode($pipelinesCode, $splitJoinesCode);
		}
	}
	return ($pipelinesCode, $splitJoinesCode);
}

1;