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

__END__

=head1 StreamGraph::Model::CodeObject::SplitJoin

The StreamGraph::Model:CodeObject::SplitJoin class implements the split-joines of StreamIt.

=head2 Properties

=over

=item C<codeObjects> (List of StreamGraph::Model::CodeObject)

List of StreamGraph::Model::CodeObject's which are directly nested in the split-join construct.


=item C<split> (StreamGraph::Model::Node::Filter)

The filter on which the splitting is occuring. 


=item C<join> (StreamGraph::Model::Node::Filter)

The filter on which the splitted streams are converging.


=item C<next> (StreamGraph::Model::Node::Filter)

The filter which is the next to be processed after completely building the codeObject.


=item C<code> (String)

The StreamIt code for the codeObject.


=item C<parameters> (List of StreamGraph::Model::CodeObject::Parameter)

The Parameters of all filters nested in the codeObject.


=item C<inputType> (String)

The type(a type in StreamIt) in which the input of the codeObject is given.


=item C<graph> (StreamGraph::GraphCompat)

The graph in which the split-join is located.


=back

=head2 Methods

=over

=item C<StreamGraph::Model::CodeObject::SplitJoin-E<gt>new($first, $graph)>

Create a StreamGraph::Model::CodeObject::SplitJoin starting on $first(a StreamGraph::Model::Node::Filter) 
in the $graph (a StreamGraph::GraphCompat). While creating the split-join it is necessary to create all nested
CodeObjects within it. Therefore these are also created which assures the StreamIt typical hierarchical structure,
as well as the complete generation of all necessary codeObjects.


=item C<getSplitCode($view)>

C<return> Code for the split or Error if a failure occured.

Generates the code for the split part of the split-join including all necessary multiplicities.


=item C<getJoinCode($view)>

C<return> Code for the join or Error if a failure occured.

Generates the code for the join part of the split-join including all necessary multiplicities.


=item C<generate($view)>

C<return> 1 if no error occured, otherwise Error 

Generates the code for the split-join, as well as all nested CodeObjects and fills the code property.


=item C<buildCode($pipelinesCode, $splitJoinesCode)>

C<return> The complete code for the codeObject and all nested codeObjects as a tuple of code for pipelines and splitJoines.

Gets all the code necessary for a StreamIt program out of the codeObject and all nested codeObjects.

=back
