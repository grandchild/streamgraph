package StreamGraph::Model::Node::Filter;

use warnings;
use strict;
use StreamGraph::Model::CodeObject::Parameter;

use Moo;
extends "StreamGraph::Model::Node";

has initCode            => ( is=>"rw", default=>"" );
has workCode            => ( is=>"rw", default=>"" );
has globalVariables     => ( is=>"rw", default=>"" );
has timesPush           => ( is=>"rw", default=>0 );
has timesPop            => ( is=>"rw", default=>0 );
has timesPeek           => ( is=>"rw", default=>0 );

has joinType            => ( is=>"rw", default=>"roundrobin" );
has splitType           => ( is=>"rw", default=>"duplicate" );

has inputType           => ( is=>"rw", default=>"void" );
has inputCount          => ( is=>"rw", default=>0 );

has outputType          => ( is=>"rw", default=>"void" );
has outputCount         => ( is=>"rw", default=>0 );

has saveMembers         => ( is=>"ro", default=>sub{[qw(
	name
	id
	x
	y
	initCode
	workCode
	globalVariables
	timesPush
	timesPop
	timesPeek
	joinType
	splitType
	inputType
	inputCount
	outputType
	outputCount
)]});

sub get_parameters {
	my $self = shift;
	my $graph = shift;
	if(!$self->isa("StreamGraph::Model::Node::Filter")){
		return ();
	}
	my $parameterTypeFlag = shift;
	if(!defined($parameterTypeFlag) || $parameterTypeFlag != 0){
		$parameterTypeFlag = 1;
	}
	my @ps = $graph->predecessors($self, "StreamGraph::Model::Node::Parameter");
	if($parameterTypeFlag == 1){
		my @parameters = ();
		foreach my $p (@ps) {
			if(!$p->{'_generated'}){
				my $newParameter = StreamGraph::Model::CodeObject::Parameter->new(node=>$p);
				$p->{'_codeObject'} = $newParameter;
				push(@parameters, $newParameter);
			} else {
				# update values
				$p->{'_codeObject'}->updateValues();
				push(@parameters, $p->{'_codeObject'});
			}
		}
		return \@parameters;
	} else {
		return \@ps;
	}
}

sub get_edge_data_to {
	my ($self, $target, $graph) = @_;
	if(!defined($graph)){
		return;
	}
	return $graph->get_edge_attribute($self, $target, 'data');
}

sub get_edge_data_from {
	my ($self, $source, $graph) = @_;
	if(!defined($graph)){
		return;
	}
	return $graph->get_edge_attribute($source, $self, 'data');	
}

sub set_edge_attribute_to {
	my ($self, $target, $graph, $key, $value) = @_;
	if(!defined($graph)){
		return;
	}
	$graph->set_edge_attribute($self, $target, $key, $value);
}

sub set_edge_attribute_from {
	my ($self, $source, $graph, $key, $value) = @_;
	if(!defined($graph)){
		return;
	}
	$graph->set_edge_attribute($source, $self, $key, $value);
}

sub set_edge_data_to {
	my ($self, $target, $graph, $inMult, $outMult) = @_;
	if(!defined($graph)){
		return;
	}
	if(undef($self) || undef($target) || undef($inMult)){
		print("either self or target are undefined or not enough parameters given");
		return;
	}
	my $previous = $self->get_edge_data_to($target, $graph);
	if(undef($previous)){
		$previous = StreamGraph::Model::ConnectionData->new();
		$self->set_edge_attribute_to($target, $graph, 'data', $previous);
	}
	$previous->inputMult($inMult);
	if(!undef($outMult)){
		$previous->outputMult($outMult);
	}
}

sub set_edge_data_from {
	my ($self, $source, $graph, $inMult, $outMult) = @_;
	if(!defined($graph)){
		return;
	}
	if(undef($self) || undef($source) || undef($inMult)){
		print("either self or source are undefined or not enough parameters given");
		return;
	}
	my $previous = $self->get_edge_data_from($source, $graph);
	if(undef($previous)){
		$previous = StreamGraph::Model::ConnectionData->new();
		$self->set_edge_attribute_from($source, $graph, 'data', $previous);
	}
	$previous->inputMult($inMult);
	if(!undef($outMult)){
		$previous->outputMult($outMult);
	}
}


1;
__END__

=head1 StreamGraph::Model::Node::Filter

The basic code component in StreamGraph. Joins data from its multiple inputs and
processes it in its work code. Then the data gets distributed over its outputs.

This class is mainly a data structure and holds all properties required to
generate the filter.

=head2 Properties

=over

=item C<initCode> (String)

The StreamIt code of the init function written in the filter from the user.

=item C<workCode> (String)

The StreamIt code of the work function written in the filter from the user.


=item C<globalVariables> (String)

The global variables text written in the filter from the user. 


=item C<timesPush> (Var)

The number of times data packets are pushed to the output in one cycle. May be 
a String or an Integer.


=item C<timesPop> (Var)

The number of times data packets are popped from the input in one cycle. May be 
a String or an Integer.


=item C<timesPeek> (Var)

The highest number which is peeked in one cycle. May be a String or an Integer.


=item C<joinType> (String)

The (StreamIt) description of the join. May be void or round robin.


=item C<splitType> (String)

The (StreamIt) description of the split. May be void, round robin or duplicate.


=item C<inputType> (String)

The StreamIt type of the input.


=item C<inputCount> (Integer)

The number of incomming data connections.


=item C<outputType> (String)

The StreamIt type of the output.


=item C<outputCount> (Integer)

The number of outgoing data connections.


=item C<saveMembers> (list[String])

The properties which are saved when the graph is saved to a file.

=back


=head3 Inherited from StreamGraph::Model::Node

See the documentation of StreamGraph::Model::Node for descriptions.

=over

=item C<$name> (String)

=item C<$id> (String)

=item C<$x> (Integer)

=item C<$y> (Integer)

=back

=head3 Inherited from StreamGraph::Model::Saveable

None.


=head2 Methods

=over

=item C<StreamGraph::Model::Node::Filter-E<gt>new($initCode, $workCode, $globalVariables, $timesPush, $timesPop, $timesPeek, $joinType, $splitType, $inputType, $inputCount, $outputType, $outputCount)>

Create a StreamGraph::Model::Node::Filter.

=item C<get_parameters($graph, $parameterTypeFlag)>

C<return> list[StreamGraphModel::Node::Parameter] or StreamGraph::Model::CodeObject::Parameter as specified.

If the C<$parameterTypeFlag> is not given or true a list[StreamGraphModel::CodeObject::Parameter] is returned. 
Otherwise a list[StreamGraphModel::Node::Parameter] is returned. The returned list has all parameters that are 
connected to the filter in the C<$graph>. 


=item C<get_edge_data_to($target, $graph)>

C<return> StreamGraph::Model::ConnectionData

Get the data attribute of the connection to the C<$target>


=item C<get_edge_data_from($source, $graph)>

C<return> StreamGraph::Model::ConnectionData

Get the data attribute of the connection from the C<$source>


=item C<set_edge_attribute_to($target, $graph, $key, $value)>

Set the generic attribute for the edge to the C<$target>.


=item C<set_edge_attribute_from($source, $graph, $key, $value)>

Set the generic attribute for the edge from the C<$source>.


=item C<set_edge_data_to($target, $graph, $inMult, $outMult)>

Set the data for the edge to the C<$target>. Requires input and output
multiplicities for the connection.


=item C<set_edge_data_from($source, $graph, $inMult, $outMult)>

Set the data for the edge from the C<$source>. Requires input and output
multiplicities for the connection.

=back

=head3 Inherited from StreamGraph::Model::Node

=over

=item C<isFilter()>

=item C<isSubgraph()>

=item C<isDataNode()>

=item C<isParameter()>

=item C<isComment()>

=item C<is_split()>

=item C<is_join()>

=item C<resetId()>

=back

=head3 Inherited from StreamGraph::Model::Saveable

=over

=item C<yaml_dump>

=back
