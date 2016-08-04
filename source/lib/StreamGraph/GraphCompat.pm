package StreamGraph::GraphCompat;

use strict;
use warnings;

use parent "StreamGraph::View::Graph";

use StreamGraph::Model::NodeFactory;
use StreamGraph::View::ItemFactory;
use Data::Dump qw(dump);


sub new {
	my ($class, $graph) = @_;
	if (!defined $graph || !$graph->isa("StreamGraph::View::Graph")) {
		print __PACKAGE__."::new(): expected '\$graph' parameter, got '$graph'.\n";
		return;
	}
	my $self = {};
	bless $self, $class;
	$self->{graph} = $graph->{graph}->new;
	$self->_copyData($graph);
	$self->{factory} = StreamGraph::Model::NodeFactory->new;
	$self->{source} = $self->_addVoidSource;
	$self->{sink} = $self->_addVoidSink;
	$self->_addIdentities;
	return $self;
}

sub graph { return shift->{graph}; }
sub source { return shift->{source}; }
sub sink { return shift->{sink}; }
sub factory { return shift->{factory}; }

sub _createItem {
	my ($graph, $data) = @_;
	# Fake-bless a simple hash into View::Item class, because we don't want the
	# whole view in here, but need View::Graph vertices to be View::Items.
	return bless({data=>$data, graph=>$graph}, "StreamGraph::View::Item");
}

sub _addIdentities {
	my $self = shift;
	foreach my $c ($self->get_connections) {
		my $pred = $c->[0];
		my $succ = $c->[1];
		#print("Does Graph of " . $pred->{data}->name . " have it?: " . $self->{graph}->has_vertex($pred));
		if ($pred->isFilter && $pred->is_split($self->graph)
				&& $succ->isFilter && $succ->is_join($self->graph)) {
			my $identity = $self->factory->createIdentity($pred->outputType); 
			# print "Should add identity between " . $pred->{data}->name . " and " . $succ->{data}->name . "\n";
			$pred->{graph} = $self;
			$self->add_vertex($identity);
			my $edgeAttr = $self->get_edge_attribute($pred, $succ, 'data');
			$self->{graph}->add_edge($pred, $identity);
			$self->set_edge_attribute($pred, $identity, 'data', StreamGraph::Model::ConnectionData->new(
				inputMult=>$edgeAttr->inputMult, inputPrio=>$edgeAttr->inputPrio));
			$self->remove_edge($pred, $succ);
			$self->{graph}->add_edge($identity, $succ);
			$self->set_edge_attribute($identity, $succ, 'data', StreamGraph::Model::ConnectionData->new(
				outputMult=>$edgeAttr->outputMult, outputPrio=>$edgeAttr->outputPrio));
		}
	}
}

# $newRoot = $self->_addVoidSplit();
sub _addVoidSource {
	my $self = shift;
	return $self->_addVoidEnd(
		"source",
		\&StreamGraph::View::Graph::predecessorless_filters,
		\&StreamGraph::Model::Node::Filter::inputType
	);
}

sub _addVoidSink {
	my $self = shift;
	return $self->_addVoidEnd(
		"sink",
		\&StreamGraph::View::Graph::successorless_filters,
		\&StreamGraph::Model::Node::Filter::outputType
	);
}

sub _addVoidEnd {
	my ($self, $type, $getEndNodes, $getIOType) = @_;
	my @endNodes = $getEndNodes->($self);
	if (@endNodes >= 1) {
		my @trueEndNodes = grep {
			$_->isFilter && $getIOType->($_) eq "void"
		} @endNodes;
		if (@trueEndNodes > 1) {
			my $voidEnd = $self->factory->createVoidEnd($type, scalar @trueEndNodes);
			foreach my $end (@trueEndNodes) {
				if ($type eq "sink") {
					$end->{graph} = $self;
					$self->{graph}->add_edge($end, $voidEnd, StreamGraph::Model::ConnectionData->new);
				} elsif ($type eq "source") {
					$self->{graph}->add_edge($voidEnd, $end, StreamGraph::Model::ConnectionData->new);
				} else {
					print "Wrong type"
				}
			}
			return $voidEnd;
		} elsif (@trueEndNodes == 1) {
			return $trueEndNodes[0];
		} else {
			print "No subgraph is streamit-compatible";
			# TODO: What should be done?
		}
	} else {
		print "Empty graph or (as a result of a GUI bug) a fully cyclic graph";
		# TODO: What should be done? Generate something here?
	}
	print " (Looking for ${type}s).\n";
	return 0;
}

sub _copyData {
	my $self = shift;
	my $graph = shift;
	foreach my $c ($graph->get_connections) {
		$self->{graph}->add_edge($c->[0]->{data}, $c->[1]->{data}, $graph->get_edge_attribute($c->[0], $c->[1], 'data')->createCopy)
	}
}

1;
