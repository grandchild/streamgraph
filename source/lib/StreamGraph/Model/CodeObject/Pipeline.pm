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

__END__

=head1 StreamGraph::Model::CodeObject::Pipeline

The StreamGraph::Model::CodeObject::Pipeline class implements StreamIt pipeplines

=head2 Properties

=over

=item C<codeObjects> (list[StreamGraph::Model::CodeObject, StreamGraph::Model::Node::Filter])

The objects which are in the pipeline in the order in which a packet of data would be processed by them. 
They may be a StreamGraph::Model::Node::Filter or a StreamGraph::Model::CodeObject (most of the time the 
StreamGraph::Model::CodeObject will be a StreamGraph::Model::CodeObject::SplitJoin). Since 
StreamGraph::Model::Node::Filter already has all relevant infromation it was not necessary to create
a filter as a codeObject, as a result of that this list has items of both StreamGraph::Model::Node::Filter
and StreamGraph::Model::CodeObject.


=item C<next> (StreamGraph::Model::Node::Filter)

The filter which is the next to be processed after completely building the codeObject.


=item C<code> (String)

StreamIt code for the pipeline.


=item C<parameters> (list[StreamGraphModel::CodeObject::Parameter])

The parameters of all filters nested in the codeObject.


=item C<inputType> (String)

The type(a type in StreamIt) in which the input of the codeObject is given.


=item C<graph> (StreamGraph::GraphCompat)

The graph in which the pipeline is located.

=back

=head3 Inherited from StreamGraph::Model::CodeObject

See the documentation of StreamGraph::Model::CodeObject for descriptions.

=over

=item C<name> (String)

=item C<outputType> (String)

=back


=head2 Methods

=over

=item C<StreamGraph::Model::CodeObject::Pipeline-E<gt>new(first=>$first, graph=>$graph)>

Create a StreamGraph::Model::CodeObject::Pipeline starting on C<$first> (a StreamGraph::Model::Node::Filter)
in the C<$graph> (a StramGraph::GraphCompat). While creating a pipeline a node with multiple outputs may be detected.
In that case it is necessary to start the generation of a split-join-construct. Since all directly nested constructs 
are needed for the later generation these nested constructs will also be created. This assures the StreamIt typical 
hierarchical structure, as well as the complete generation of all necessary codeObjects.


=item C<generate($view, $mainFlag)>

C<return> 1 if no error occured, otherwise Error

Generates the code for the pipeline, as well as all nested CodeObjects and fills the code property. If C<$mainFlag>
is set to true the generated pipeline will be treated as the main pipeline, which means, that its name will be the 
name of the project. This property will not be carried on to nested codeObjects, so that there exists only one main
pipeline in every project.


=item C<buildCode($pipelinesCode, $splitJoinesCode)>

C<return> The complete code for the codeObject and all nested codeObjects as a tuple of code for pipelines and split-joines.

Gets all the code necessary for a StreamIt program out of the codeObject and all nested codeObjects.

=back

=head3 Inherited from StreamGraph::Model::CodeObject

None.