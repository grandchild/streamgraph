package StreamGraph::GraphCompat;

use strict;
use warnings;

use parent "StreamGraph::View::Graph";

use StreamGraph::Model::NodeFactory;
use StreamGraph::View::ItemFactory;


sub new {
	my ($class, $graph) = @_;
	if (!defined $graph || !$graph->isa("StreamGraph::View::Graph")) {
		print __PACKAGE__."::new(): expected '\$graph' parameter, got '$graph'.\n";
		return;
	}
	my $self = {};
	bless $self, $class;
	$self->{graph} = $graph->{graph}->copy_graph;
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
	# Fake-bless a simple hash into View::Item class, because we don't want the
	# whole view in here, but need View::Graph vertices to be View::Items.
	return bless({data=>shift}, "StreamGraph::View::Item");
}

sub _addIdentities {
	my $self = shift;
	foreach my $c ($self->get_connections) {
		my $pred = $c->[0];
		my $succ = $c->[1];
		if ($pred->isFilter && $pred->is_split
				&& $succ->isFilter && $succ->is_join) {
			my $identity = _createItem(
				$self->factory->createIdentity($pred->{data}->outputType)
			);
			# print "Should add identity between " . $pred->{data}->name . " and " . $succ->{data}->name . "\n";
			$self->add_vertex($identity);
			$self->add_edge($pred, $identity);
			$self->remove_edge($pred, $succ);
			$self->add_edge($identity, $succ);
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
			$_->isFilter && $getIOType->($_->{data}) eq "void"
		} @endNodes;
		if (@trueEndNodes > 1) {
			my $voidEnd = _createItem(
				$self->factory->createVoidEnd($type, scalar @trueEndNodes)
			);
			foreach my $end (@trueEndNodes) {
				if ($type eq "sink") {
					$self->add_edge($end, $voidEnd);
				} elsif ($type eq "source") {
					$self->add_edge($voidEnd, $end);
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

1;
