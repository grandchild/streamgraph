package StreamGraph::GraphCompat;

use strict;
use warnings;

use parent "StreamGraph::View::Graph";

use StreamGraph::Model::NodeFactory;
use StreamGraph::Model::ConnectionData;
use StreamGraph::Model::Namespace;
use StreamGraph::Util::File;
use StreamGraph::Util qw(getNodeWithId);


sub new {
	my ($class, $graph) = @_;
	if (!defined $graph || !$graph->isa("StreamGraph::View::Graph")) {
		print __PACKAGE__."::new(): expected '\$graph' parameter, got '$graph'.\n";
		return;
	}
	my $self = {};
	bless $self, $class;
	$self->{graph} = $graph->{graph}->new;
	$self->{factory} = StreamGraph::Model::NodeFactory->new;
	$self->_copyData($graph);
	$self->_subgraphs;
	$self->{source} = $self->_addVoidSource;
	$self->{sink} = $self->_addVoidSink;
	$self->{success} &&= not ($self->{source} == 0 or $self->{sink} == 0);
	$self->_addIdentities;
	return $self;
}

sub graph { return shift->{graph}; }
sub source { return shift->{source}; }
sub sink { return shift->{sink}; }
sub factory { return shift->{factory}; }
sub success { return shift->{success}; }


sub _addIdentities {
	my $self = shift;
	foreach my $c ($self->get_connections) {
		my $pred = $c->[0];
		my $succ = $c->[1];
		if ($pred->isFilter && $pred->is_split($self->graph)
				&& $succ->isFilter && $succ->is_join($self->graph)) {
			my $identity = $self->factory->createIdentity($pred->outputType); 
			$pred->{graph} = $self;
			$self->add_vertex($identity);
			my $edgeAttr = $self->get_edge_attribute($pred, $succ, 'data');
			$self->{graph}->add_edge($pred, $identity);
			$self->set_edge_attribute($pred, $identity, 'data', StreamGraph::Model::ConnectionData->new(
				inputMult=>$edgeAttr->inputMult));
			$self->remove_edge($pred, $succ);
			$self->{graph}->add_edge($identity, $succ);
			$self->set_edge_attribute($identity, $succ, 'data', StreamGraph::Model::ConnectionData->new(
				outputMult=>$edgeAttr->outputMult));
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
					$self->{graph}->add_edge($end, $voidEnd);
					$self->{graph}->set_edge_attribute($end, $voidEnd, 'data', StreamGraph::Model::ConnectionData->new);
				} elsif ($type eq "source") {
					$self->{graph}->add_edge($voidEnd, $end);
					$self->{graph}->set_edge_attribute($voidEnd, $end, 'data', StreamGraph::Model::ConnectionData->new);
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

sub _subgraphs {
	my ($self) = @_;
	foreach my $n ($self->graph->vertices) {
		if ($n->isSubgraph) {
			$self->_subgraph($n);
		}
	}
}

sub _subgraph {
	my ($self, $n) = @_;
	my $checkGraph = _loadFile($n->filepath);
	if (not defined $checkGraph) {
		print("Failed to load subgraph '", $n->name, "'\n");
		$self->{success} = 0;
		return;
	}
	my @sources = grep { not $_->inputType eq "void" } $checkGraph->predecessorless_filters;
	my @sinks = grep { not $_->outputType eq "void" } $checkGraph->successorless_filters;
	if (@sources + @sinks <= 2 and @sources + @sinks >= 1) {
		my (@incoming, @outgoing);
		if (@sources) {
			if (not $sources[0]->inputType eq $n->inputType) {
				print("Input type '", $n->inputType, "' of Subgraph node '", $n->name, "' doesn't match inner source input type '", $sources[0]->inputType, "'.\n");
				$self->{success} = 0;
			}
			@incoming = map { {node=>$_, data=>$self->graph->get_edge_attribute($_, $n, 'data')} } $self->predecessors($n);
		}
		if (@sinks) {
			if (not $sinks[0]->outputType eq $n->outputType) {
				print("Output type '", $n->outputType, "' of Subgraph node '", $n->name, "' doesn't match inner sink output type '", $sinks[0]->outputType, "'.\n");
				$self->{success} = 0;
			}
			@outgoing = map { {node=>$_, data=>$self->graph->get_edge_attribute($n, $_, 'data')} } $self->successors($n);
		}
		$self->remove_vertex($n);
		
		my @subsubgraphs = ();
		map {
			my $item = $_;
			$self->graph->add_vertex($item);
			map {
				my $node = $_->{node};
				if($node->isParameter) {
					$self->graph->add_edge($node, $item);
				}
			} @incoming;
			push(@subsubgraphs, $_) if ($_->isSubgraph);
		} $checkGraph->get_items;
		map {
			my ($from, $to) = @$_;
			$self->graph->add_edge($from, $to);
			$self->graph->set_edge_attribute($from, $to, 'data', $checkGraph->get_edge_attribute($from, $to, 'data'));
		} $checkGraph->get_connections;
		
		if (@sources) {
			map {
				$self->graph->add_edge($_->{node}, $sources[0]);
				$self->graph->set_edge_attribute($_->{node}, $sources[0], 'data', $_->{data});
			} @incoming;
		}
		if (@sinks) {
			map {
				$self->graph->add_edge($sinks[0], $_->{node});
				$self->graph->set_edge_attribute($sinks[0], $_->{node}, 'data', $_->{data});
			} @outgoing;
		}
		map { $self->_subgraph($_); } @subsubgraphs;
	} elsif (@sources==0 or @sinks==0) {
		print("Subgraph is empty or has no none-void sources or sinks. Trying to continue by removing the subgraph...\n");
		$self->remove_vertex($n);
		# FIXME:
		# Check now if all successors and predecessors still have other nodes
		# connected in the same direction.
		# If not throw an error, as this would leave them with empty pins.
	} else {
		print("Multiple sources (" . @sources . ") and/or sinks (" . @sinks . ") in subgraph. Only a single source and/or a single sink may be used.\n");
		foreach my $s (@sources) {
			print $s->name, " (", $s->id, ")\n";
		}
		foreach my $s (@sinks) {
			print $s->name, " (", $s->id, ")\n";
		}
		$self->{success} = 0;
	}
}

sub _copyData {
	my $self = shift;
	my $graph = shift;
	foreach my $c ($graph->get_connections) {
		$self->{graph}->add_edge($c->[0]->{data}, $c->[1]->{data});
		$self->{graph}->set_edge_attribute($c->[0]->{data}, $c->[1]->{data}, 'data', $graph->get_edge_attribute($c->[0], $c->[1], 'data')->createCopy)
	}
}

sub _loadFile {
	my ($filepath) = @_;
	my $graph = StreamGraph::View::Graph->new();
	return if not defined $graph;
	my ($wd, $nodes, $connections) = StreamGraph::Util::File::load($filepath);
	my $nodeFactory = StreamGraph::Model::NodeFactory->new;
	map {
		$graph->add_vertex($_);
	} @{$nodes};
	map {
		my $data = $_->{data} ?
			StreamGraph::Model::ConnectionData->new($_->{data}) :
			StreamGraph::Model::ConnectionData->new;
		my @graphnodes = $graph->get_items;
		my $from = getNodeWithId(\@graphnodes, $_->{from});
		my $to = getNodeWithId(\@graphnodes, $_->{to});
		$graph->{graph}->add_edge($from, $to);
		$graph->{graph}->set_edge_attribute($from, $to, 'data', $data);
	} @{$connections};
	my $namespace = StreamGraph::Model::Namespace->new(filepath=>$filepath);
	foreach my $n ($graph->get_items) {
		$n->resetId;
		if ($n->isParameter) {
			$namespace->register($n->name);
			$n->name($namespace->newname($n->name));
		}
	}
	$namespace->replaceAll($graph);
	return $graph;
}

1;

__END__

=head1 StreamGraph::GraphCompat

The StreamGraph::GraphCompat class assures that a graph is StreamIt compatible. 
It inherits from the StreamGraph::View::Graph class.

=head2 Properties

The StreamGraph::GraphCompat class inherits all properties of the 
StreamGraph::View::Graph and adds none of itself. Therefore all Properties can be
looked up at the StreamGraph::View::Graph documentation.

=head2 Methods

=over

=item C<StreamGraph::GraphCompat-E<gt>new($graph)>

Create a StreamGraph::GraphCompat out of the given StreamGraph::View::Graph. 
Essentially a copy of the given $graph only with the necessary data is created.

=item C<graph()>

C<return> Graph property of the StreamGraph::GraphCompat

Simple accessor for the graph property


=item C<source()>

C<return> source property of the StreamGraph::GraphCompat 

Simple accessor for the source property


=item C<sink()>

C<return> sink property of the StreamGraph::GraphCompat

Simple accessor for the sink property


=item C<factory()>

C<return> factory property of the StreamGraph::GraphCompat

Simple accessor for the factory property


=item C<success()>

C<return> success property of the StreamGraph::GraphCompat

Simple accessor for the success property


=item C<_addIdentities()>

Adds identity nodes on all connections between a spilt and a join node.


=item C<_addVoidSource(parameters)>

C<return> returnvalue

description


=item C<_addVoidSink(parameters)>

C<return> returnvalue

description


=item C<_addVoidEnd(parameters)>

C<return> returnvalue

description


=item C<_subgraphs(parameters)>

C<return> returnvalue

description


=item C<_subgraph(parameters)>

C<return> returnvalue

description


=item C<_copyData($graph)>

Copies the important data(nodes, connections and connection-attributes) 
from the $graph to the StreamGraph::GraphCompat.


=item C<_loadFile(parameters)>

C<return> returnvalue

description

=back
