package StreamGraph::Model::NodeFactory;

use warnings;
use strict;

use Moo;

use StreamGraph::Model::Node::Filter;
use StreamGraph::Model::Node::Subgraph;
use StreamGraph::Model::Node::Parameter;
use StreamGraph::Model::Node::Comment;


sub createNode {
	my ($self, @attributes) = @_;
	my %attributes = @attributes;
	my $attributes = @attributes;
	my $type = delete $attributes{type};
	return $type->new(%attributes);
}

sub createIdentity {
	my ($self, $datatype) = @_;
	return StreamGraph::Model::Node::Filter->new(
		name=>"__identity__",
		workCode=>"push(pop());",
		timesPush=>1,
		timesPop=>1,
		inputType=>$datatype,
		inputCount=>1,
		outputType=>$datatype,
		outputCount=>1
	);
}

sub createVoidEnd {
	my ($self, $type, $count) = @_;
	if ($type eq "sink") {
		return StreamGraph::Model::Node::Filter->new(
			name=>"__void_sink__",
			joinType=>"void",
			joinMultiplicities=>(0),
			inputCount=>$count,
		);
	} elsif ($type eq "source") {
		return StreamGraph::Model::Node::Filter->new(
			name=>"__void_source__",
			splitType=>"void",
			splitMultiplicities=>(0),
			outputCount=>$count
		);
	} else {
		print __PACKAGE__."::createVoidEnd(): Wrong type '$type'.\n";
		return 0;
	}
}

1;
__END__

=head1 StreamGraph::Model::NodeFactory

Create general Nodes and some standardized nodes for StreamGraph::GraphCompat.

=head2 Properties

None.

=head2 Methods

=over

=item C<StreamGraph::Model::NodeFactory-E<gt>new()>

Create a StreamGraph::Model::NodeFactory.

=item C<createNode(@attributes)>

C<return> a new node of type C<$attributes{"type"}>.

Takes a hash of C<%attributes> to pass to the new node.


=item C<createIdentity($datatype)>

C<return> a new node of type StreamGraph::Model::Filter. 

The created filter will have the work section of

	push(pop());

and so will pass on all data packets unchanged.

This function is used by StreamGraph::GraphCompat.


=item C<createVoidEnd($type, $count)>

C<return> a new node of type StreamGraph::Model::Filter or 0 on error if the
C<$type> is invalid.

C<$type> is a string and can either be C<"source"> or C<"sink">.

C<$count> determines how many outputs (source) or inputs (sink) the node will
have.

=back
