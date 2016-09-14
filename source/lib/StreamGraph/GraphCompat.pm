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

None.

=head3 Inherited from StreamGraph::View::Graph

=over

=item C<$graph>

=item C<$root>

=back

=head2 Methods

=over

=item C<StreamGraph::GraphCompat-E<gt>new($graph)>

Create a StreamGraph::GraphCompat from the given StreamGraph::View::Graph.
This is essentially a deep copy of the given C<$graph> with its
StreamGraph::View::Items unpacked into plain StreamGraph::Model::Nodes.

=item C<graph()>

C<return> graph (Graph::Directed)


=item C<source()>

C<return> source (StreamGraph::Model::Node::Filter)


=item C<sink()>

C<return> sink (StreamGraph::Model::Node::Filter)


=item C<factory()>

C<return> factory (StreamGraph::Model::NodeFactory)


=item C<success()>

C<return> success (Boolean)


=item C<_addIdentities()>

Adds identities throughout the graph for all connections whose two nodes have
other paths between them as well.


=item C<_addVoidSource()>

C<return> the graph's source (StreamGraph::Model::Node::Filter) or 0 on error.

If there are multiple sources in the graph, adds a new filter with a void-
typed input joining all sources.

If there is only one source, then return this source filter unchanged.


=item C<_addVoidSink()>

C<return> the graph's sink (StreamGraph::Model::Node::Filter) or 0 on error. 

If there are multiple sinks in the graph, adds a new filter with a void-typed
output joining all sinks.

If there is only one sink, then return this sink filter unchanged.


=item C<_addVoidEnd($type, $getEndNodes, $getIOType)>

C<return> the created end node(StreamGraph::Model::Node::Filter)

Takes a C<$type>(String), either C<"source> or C<"sink"> and two functions,
C<$getEndNodes> to filter the relevant end nodes, and C<$getIOType> to get the
type of the relevant pins. It then checks whether there are multiple sources
or sinks and if there are creates a void end, connects it and returns it.


=item C<_subgraphs()>

Flatten all subgraph nodes (and their children recursively) into the parent graph
structure. See C<_subgraph()> for details.


=item C<_subgraph($n)>

Flatten a subgraph node C<$n> (StreamGraph::Model::Node) into the parent graph
structure.

The subgraph is loaded, parsed and checked for errors. If there are errors in
the subgraph, it is skipped and this parent graph is also marked as failed.

The loaded subgraph's nodes and connections are inserted into the parent graph
and connected inline.

=item C<_copyData($graph)>

Copies nodes, connections and connection-attributes from the constructor
argument C<$graph> to this $graph.


=item C<_loadFile($filepath)>

C<return> a graph (StreamGraph::GraphCompat) loaded from C<$filepath>.

Static method that loads and parses a file into a temporary
StreamGraph::GraphCompat instance and namespaces all it's parameters (See
StreamGraph::Model::Namespace for details).

=back

=head3 Inherited from StreamGraph::View::Graph

=over

=item C<add_vertex()>

=item C<add_edge()>

=item C<get_edge_attribute()>

=item C<set_edge_attribute()>

=item C<get_root()>

=item C<has_item()>

=item C<get_items()>

=item C<get_connections()>

=item C<num_items()>

=item C<predecessors()>

=item C<remove_vertex()>

=item C<remove_edge()>

=item C<successors()>

=item C<all_successors()>

=item C<topological_sort()>

=item C<all_non_predecessors()>

=item C<is_predecessor()>

=item C<is_successor()>

=item C<successorless_filters()>

=item C<predecessorless_filters()>

=item C<set_root()>

=item C<traverse_BFS()>

=item C<traverse_DFS()>

=item C<traverse_postorder_edge()>

=item C<traverse_preorder_edge()>

=item C<same()>

=item C<sameErr()>

=item C<connected()>

=item C<circle()>

=item C<typeCompatible()>

=item C<directlyConnected()>

=item C<nextSplitJoin()>

=item C<crossConnection()>

=item C<lca()>

=item C<connectable()>

=item C<connectableErr()>

=item C<connectableQuiet()>

=back
