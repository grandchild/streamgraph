package StreamGraph::Model::NodeFactory;

use warnings;
use strict;

use Moo;

use StreamGraph::Model::Node::Filter;
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
			joinType=>"roundrobin",
			joinMultiplicities=>(0),
			inputCount=>$count,
		);
	} elsif ($type eq "source") {
		return StreamGraph::Model::Node::Filter->new(
			name=>"__void_source__",
			splitType=>"roundrobin",
			splitMultiplicities=>(0),
			outputCount=>$count
		);
	} else {
		print __PACKAGE__."::createVoidEnd(): Wrong type '$type'.\n";
		return 0;
	}
}

1;
