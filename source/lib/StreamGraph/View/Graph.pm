package StreamGraph::View::Graph;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Graph::Directed;
use Set::Object qw(set);
use Data::Dump qw(dump);

use StreamGraph::Model::ConnectionData;
use StreamGraph::Util qw(unique filterNodesForType);


sub new {
	my $class = shift(@_);
	my $self = {};
	bless $self, $class;
	$self->{graph} = Graph::Directed->new(refvertexed=>1);
	$self->{root}  = undef;
	return $self;
}

# $graph->add($item);
sub add_vertex {
	my ($self, $item) = @_;
	$self->{graph}->add_vertex($item);
	if (!defined $self->{root}) {
		$self->{root} = $item;
	}
}

# $graph->add($predecessor_item,$item);
sub add_edge {
	my ($self, $item1, $item2, $connection_data) = @_;
	if ((!defined $item1) or (!defined $item2)) {
		croak "You must specify two items to connect.\n";
	}
	my ($isConnectable, $err) = $self->connectable($item1, $item2, "down");
	return $err if not $isConnectable;
	$self->add_vertex($item1) if (!$self->has_item($item1));
	$self->add_vertex($item2) if (!$self->has_item($item2));
	$self->{graph}->add_edge($item1, $item2);
	if (not defined $connection_data) {
		$connection_data = StreamGraph::Model::ConnectionData->new;
	}
	$self->set_edge_attribute($item1, $item2, 'data', $connection_data);
	return "";
}

sub get_edge_attribute{
	my ($self, $item1, $item2, $key) = @_;
	return $self->{graph}->get_edge_attribute($item1, $item2, $key);
}

sub set_edge_attribute{
	my ($self, $item1, $item2, $key, $value) = @_;
	return $self->{graph}->set_edge_attribute($item1, $item2, $key, $value);
}


sub is_connectable {
	my ($self, $item1, $item2) = @_;
	if ($item1->isDataNode and $item2->isDataNode) {
		if ($item1->{data}->outputType ne $item2->{data}->inputType) {
			print "Output type " . $item1->{data}->outputType .
					" does not match input type " . $item2->{data}->inputType . ".\n";
			return 0;
		}
	} elsif ($item1->isParameter and $item2->isDataNode) {
	} else {
		print "You cannot connect these types of items: " .
			ref($item1->{data}) . " and " . ref($item2->{data}) . ".\n";
		return 0;
	}
	if ($self->is_predecessor($item1, $item2) || $item1 eq $item2) {
		$item1->{view}->println("Trying to form a cicle.",'dialog-error');
		return 0;
	}
	return 1;
}

# $root = $graph->get_root();
sub get_root {
	my $self = shift(@_);
	return $self->{root};
}


# $boolean = $graph->has_item($item);
sub has_item {
	my ($self, $item) = @_;
	return $self->{graph}->has_vertex($item);
}

sub get_items {
	my $self = shift(@_);
	my @items = $self->{graph}->vertices();
	return @items;
}

sub get_connections {
	my $self = shift(@_);
	my @edges = $self->{graph}->edges();
	return @edges;
}

# $num_items = $graph->num_items();
sub num_items {
	my $self = shift(@_);
	my $num_items = $self->{graph}->vertices();
	return $num_items;
}


# @predecessors = $graph->predecessors($item);
sub predecessors {
	my ($self, $item, $type) = @_;
	if(!defined $self->{graph}){
		return ();
	}
	if(defined $type){
		return grep { $_->isa($type) } $self->{graph}->predecessors($item);
	} else {
		return $self->{graph}->predecessors($item);
	}
}


# $graph->remove_vertex($item);
sub remove_vertex {
	my ($self, $item) = @_;
	my @successors = $self->{graph}->successors($item);
	my @predecessors = $self->{graph}->predecessors($item);
	for my $successor (@successors) {
		$self->{graph}->delete_edge($successor, $item);
	}
	for my $predecessor (@predecessors) {
		$self->{graph}->delete_edge($predecessor, $item);
	}

	$self->{graph}->delete_vertex($item);
}

sub remove_edge {
	my ($self, $item1, $item2) = @_;
	$self->{graph}->delete_edge($item1, $item2);
}

# @successors = $graph->successors($item);
sub successors {
	my ($self, $item) = @_;
	return $self->{graph}->successors($item);
}

# @successors = $graph->successors($item);
sub all_successors {
	my ($self, $item) = @_;
	# change to:
	return $self->{graph}->all_successors($item);
}


# @all_nodes = $graph->topological_sort();
sub topological_sort {
	my ($self) = @_;
	return $self->{graph}->topological_sort();
}

# @downstream = $graph->all_non_predecessors($item);
sub all_non_predecessors {
	my ($self, $item) = @_;
	my @predecessors = $self->{graph}->all_predecessors($item);
	push @predecessors, $item;
	my @items;
	foreach my $ai ($self->get_items) {
		my $is_predecessor = 0;
		foreach my $pi (@predecessors) {
			if ($self->same($ai, $pi)) {
				$is_predecessor = 1;
				last;
			}
		}
		push(@items, $ai) if !$is_predecessor;
	}
	return @items;
}

sub is_predecessor {
	my ($self, $item, $potential_predecessor) = @_;
	foreach my $pi ($self->{graph}->all_predecessors($item)) {
		return 1 if $self->same($pi, $potential_predecessor);
	}
	return 0;
}

sub is_successor {
	my ($self, $item, $potential_successor) = @_;
	foreach my $si ($self->{graph}->all_successors($item)) {
		return 1 if $self->same($si, $potential_successor);
	}
	return 0;
}

sub successorless_filters {
	my ($self) = @_;
	return $self->{graph}->successorless_vertices;
}

sub predecessorless_filters {
	my ($self) = @_;
	my @sourceFilters = ();
	foreach my $item ($self->get_items) {
		if ($item->isa("StreamGraph::Model::Node::Filter")) {
			if ($self->predecessors($item, "StreamGraph::Model::Node::Filter") == 0) {
				push @sourceFilters, $item;
			}
		}
	}
	return @sourceFilters;
}

# $graph->set_root($item);
sub set_root {
	my ($self, $item) = @_;
	my $graph = $self->{graph};
	my $new_graph = Graph::Directed->new(refvertexed=>1);
	$new_graph->add_vertex($item);
	_set_root($self, $new_graph, $item, undef);
	$self->{graph} = $new_graph;
	$self->{root} = $item;
}


# $graph->traverse_BFS($item, $callack);
sub traverse_BFS {
	my ($self, $item, $callback) = @_;
	my @pairs = ();
	_traverse_pairs($self, \@pairs, 0, $item);
	my @sorted_pairs = sort { ($a->[0] <=> $b->[0]) ||
					($a->[1] <=> $b->[1]) } @pairs;
	foreach my $pair_ref (@sorted_pairs) {
		&$callback($pair_ref->[1]);
	}
}


# $graph->traverse_DFS($item, $callback)
sub traverse_DFS {
	my ($self, $item, $callback) = @_;
	&$callback($item);
	my @successors = $self->{graph}->successors($item);
	foreach my $successor_item (@successors) {
		$self->traverse_DFS($successor_item, $callback);
	}
}


# $graph->traverse_postorder_edge($predecessor_item, $item, $callback);
sub traverse_postorder_edge {
	my ($self, $predecessor_item, $item, $callback) = @_;
	my @successors = $self->{graph}->successors($item);
	foreach my $successor_item (@successors) {
		traverse_postorder_edge($self, $item, $successor_item, $callback);
	}
	&$callback($predecessor_item, $item);
}


# $graph->traverse_preorder_edge($predecessor_item, $item, $callback);
sub traverse_preorder_edge {
	my ($self, $predecessor_item, $item, $callback) = @_;
	&$callback($predecessor_item, $item);
	my @successors = $self->{graph}->successors($item);
	foreach my $successor_item (@successors) {
		traverse_preorder_edge($self, $item, $successor_item, $callback);
	}
}


sub _set_root {
	my ($self, $new_graph, $item, $verboten_item) = @_;
	my @successors = $self->{graph}->successors($item);
	foreach my $successor_item (@successors) {
		next if ((defined $verboten_item) && ($successor_item == $verboten_item));
		$self->traverse_preorder_edge($item, $successor_item,
				 sub { $new_graph->add_edge($_[0], $_[1]); });
	}
	my @predecessors = $self->{graph}->predecessors($item);
	foreach my $predecessor_item (@predecessors) {
		$new_graph->add_edge($item, $predecessor_item);
		_set_root($self, $new_graph, $predecessor_item, $item);
	}
}


sub _traverse_pairs {
	my ($self, $pairs_ref, $level, $item) = @_;
	push @{$pairs_ref}, [$level, $item];
	my @successors = $self->{graph}->successors($item);
	foreach my $successor_item (@successors) {
		_traverse_pairs($self, $pairs_ref, $level + 1, $successor_item);
	}
}

# Connectability tests and helpers
sub same {
	my ($self, $node1, $node2) = @_;
	my ($isSame, $err) = $self->sameErr($node1, $node2);
	return $isSame;
}
sub sameErr {
	my ($self, $node1, $node2) = @_;
	return (0, "") if (!defined($node1) or !defined($node2) or !defined($node1->{data}) or !defined($node2->{data}));
	if ($node1->{data}->id eq $node2->{data}->id) {
		return (1, "It's the same node.\n");
	} else {
		return (0, "It's not the same node.\n");
	}
}

sub connected {
	my ($self, $node1, $node2, $direction) = @_;
	($node1, $node2) = ($node2, $node1) if $direction eq "up";
	if ($self->{graph}->has_edge($node1, $node2)) {
		return (1, _formatNodes($node1, $node2) . " are already connected.\n");
	} else {
		return (0, _formatNodes($node1, $node2) . " are not connected.\n");
	}
}

sub circle {
	my ($self, $node1, $node2, $direction) = @_;
	($node1, $node2) = ($node2, $node1) if $direction eq "up";
	if ($self->is_predecessor($node1, $node2) or $node1 eq $node2) {
		return (1, "Trying to form a circle (" . _formatNodes($node1, $node2) . ").\n");
	} else {
		return (0, "");
	}
}

sub typeCompatible {
	my ($self, $node1, $node2, $direction) = @_;
	($node1, $node2) = ($node2, $node1) if $direction eq "up";
	if ($node1->isDataNode and $node2->isDataNode) {
		if ($node1->{data}->outputType ne $node2->{data}->inputType) {
			return (0, "Output type " . $node1->{data}->outputType . " does not match input type " . $node2->{data}->inputType . ".\n");
		}
		return (1, "");
	} elsif ($node1->isParameter and $node2->isDataNode) {
		return (1, "");
	} else {
		return (0, "You cannot connect these types of items. (" . _formatNodeTypes($node1, $node2) . ")\n");
	}
}

sub directlyConnected {
	my ($self, $node1, $node2, $direction) = @_;
	($node1, $node2) = ($node2, $node1) if $direction eq "up";
	return $self->is_successor($node1, $node2);
}

sub nextSplitJoin {
	my ($self, $node, $direction) = @_;
	my $curNode = $node;
	if($direction eq "up") {
		while ($node->successors > 0 and ($node->successors)[0]) {
			last;
		}
	} else {
		# print("Filtering...\n");
		# print("predecessors: ", ref($curNode->predecessors), " -- ", scalar $curNode->predecessors, "\n");
		my @predecessors = filterNodesForType($curNode->predecessors, "StreamGraph::Model::Node::Filter");
		# print("Done filtering: ", ref(\@predecessors), "\n");
		while (@predecessors > 0 and $predecessors[0]) {
			if($predecessors[0]->is_split) {
				$curNode = $predecessors[0];
				@predecessors = filterNodesForType($curNode->predecessors, "StreamGraph::Model::Node::Filter");
				my $graphCompat = StreamGraph::GraphCompat->new($curNode->{graph});
				my $splitJoin = StreamGraph::Model::CodeObject::SplitJoin->new(first=>$curNode->{data}, graph=>$graphCompat);
				if(!defined $splitJoin->next) {
					last;
				}
				if($self->is_successor($node, $splitJoin->next)) {
					last;
				}
			} else {
				$curNode = $predecessors[0];
			}
		}
	}
	return $curNode;
}

# Given two nodes, return true iff there exists any path between a successor of
# the would-be predecessor node and a predecessor of the would-be successor
# node.
#
# A   B
# |\.´|  <- An attempted connection B..D would return true because A and E are
# | \ C     already connected.
# |.´\|
# D   E
sub crossConnection {
	my ($self, $node1, $node2, $direction) = @_;
	if ($node1->connections($direction)) {
		if ($self->directlyConnected($node1, $node2, $direction)) {
			return (0, "");
		} else {
			my $nextSplitJoin = $self->nextSplitJoin($node1, $direction);
			# print("Looking for splitjoin ", _formatNodes($node1, $node2), " - found ", $nextSplitJoin->{data}->name, "\n");
			if ($self->is_predecessor($nextSplitJoin, $node2)) {
				return (0, "");
			}
			return (1, "You cannot connect across pipelines.\n");
		}
	} else {
		return (0, "");
	}
	# ($node1, $node2) = ($node2, $node1) if $direction eq "up";
	# if ($self->is_successor($node1, $node2)) {
	# 	my $innerNodes = $self->_innerNodes($node1, $node2, $direction);
	# 	if ($innerNodes->size) {
	# 		my $innerNodesInclusive = set($innerNodes->members);
	# 		$innerNodesInclusive->insert($node1, $node2);
	# 		return (0, "") if not $self->_outsideConnections($innerNodes, $innerNodesInclusive);
	# 	} else {
	# 		print "Don't even try..\n";
	# 	}
	# 	my $lca = $self->lca($node1, $node2, $direction eq "up" ? "down" : "up");
	# 	if (not $lca) {
	# 		return (1, "Cannot determine lowest common ancestor " . _formatNodes($node1, $node2) . ".\n");
	# 	}
	# 	if ($direction eq "up") {
	# 		return (0, "") if $lca->is_join;
	# 	} else {
	# 		return (0, "") if $lca->is_split;
	# 	}
	# 	return (1, "You cannot connect across pipelines.\n");
	# }
}
# Given two nodes, return all nodes that lie between those two. Betweenness is
# defined here as 'is a successor of node1 as well as a predecessor of node2'.
sub _innerNodes {
	my ($self, $node1, $node2, $direction) = @_;
	($node1, $node2) = ($node2, $node1) if $direction eq "up";
	my $set1 = set($self->{graph}->all_successors($node1));
	my $set2 = set($self->{graph}->all_predecessors($node2));
	my $intersection = $set1 * $set2;
	return $intersection;
}
# Given two sets of nodes, return true iff there is a connection from a node in
# set1 to a node that is _not_ within set2.
sub _outsideConnections {
	my ($self, $set1, $set2) = @_;
	my $outside = 0;
	# print($_->{data}->name, "\n") foreach $innerNodes->members;
	foreach my $node1 ($set1->members) {
		$outside |= not $set2->has([$_]) foreach $node1->predecessors;
		$outside |= not $set2->has([$_]) foreach $node1->successors;
	}
	return $outside;
}

# Determine the "lowest common ancestor" between two nodes. The LCA is the
# first node in the specified direction that is a predecessor/successor of
# the two.
# It's possible that one of the given nodes is the LCA itself (if there is a
# straight path between them).
# If no LCA can be determined (unconnected in the specified direction) 'undef'
# will be returned.
sub lca {
	my ($self, $node1, $node2, $direction) = @_;
	($node1, $node2) = ($node2, $node1) if $direction eq "up";

	return $node1 if $self->same($node1, $node2);
	my ($refNode, $searchNode) = ($node1, $node2);
	my $relatives = set();
	if ($direction eq "up") {
		($refNode, $searchNode) = ($node2, $node1) if $node1->{y} > $node2->{y};
		$relatives->insert($refNode, $self->{graph}->all_predecessors($refNode));
	} else {
		($refNode, $searchNode) = ($node2, $node1) if $node1->{y} < $node2->{y};
		$relatives->insert($refNode, $self->{graph}->all_successors($refNode));
	}
	my $curNode = $searchNode;
	while(defined($curNode)) {
		# print $curNode->{data}->name, "has?:", $relatives->has($curNode)?"yes":"no", "\n";
		last if $relatives->has($curNode);
		my @next;
		if ($direction eq "up") {
			@next = $curNode->predecessors;
		} else {
			@next = $curNode->successors;
		}
		if (@next) {
			foreach(@next) {
				$curNode = $_;
				last if $_->isFilter;
			}
		} else {
			$curNode = undef;
		}
	}
	# print "Found LCA ${direction}wards between ", _formatNodes($refNode, $searchNode), ": ", $curNode->{data}->name, "\n" if $curNode;
	return $curNode;
}


sub connectable {
	my ($self, $node1, $node2, $direction) = @_;
	$direction = $direction || "down";
	my $err = "";
	(my $isSame, $err) = $self->sameErr($node1, $node2);
	return (0, $err) if $isSame;
	(my $isConnected, $err) = $self->connected($node1, $node2, $direction);
	return (0, $err) if $isConnected;
	(my $isTypeCompatible, $err) = $self->typeCompatible($node1, $node2, $direction);
	return (0, $err) if not $isTypeCompatible;
	(my $isCircle, $err) = $self->circle($node1, $node2, $direction);
	return (0, $err) if $isCircle;
	# if($node1->isFilter and $node2->isFilter) {
	# 	(my $isCrossConnection, $err) = $self->crossConnection($node1, $node2, $direction);
	# 	return (0, $err) if $isCrossConnection;
	# }
	return (1, $err);
}
sub connectableErr {
	my ($self, $item1, $item2, $direction) = @_;
	my ($isConnectable, $err) = $self->connectable($item1, $item2, $direction);
	print $err if not $isConnectable;
	return $isConnectable;
}
sub connectableQuiet {
	my ($self, $item1, $item2, $direction) = @_;
	my ($isConnectable, $err) = $self->connectable($item1, $item2, $direction);
	return $isConnectable;
}


sub _formatNodes { return shift->{data}->name . " -> " . shift->{data}->name; }
sub _formatNodeTypes { return ref(shift->{data}) . " -> " . ref(shift->{data}); }

1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Graph

This is internal to StreamGraph::View. It's a wrapper around
Jarkko Heitaniemi's nice Graph module. This module is instantiated by
StreamGraph::View.

=over

=item C<StreamGraph::View::Graph-<gt>new()>

Create a StreamGraph::View::Graph.

=item C<add ($item)>

Add a root StreamGraph::View::Item to the graph. Only one of these
may be added, or you will get an error.

=item C<add ($predecessor_item, $item)>

Add a StreamGraph::View::Item to the graph. Attach the item to the
predecessor item.

=item C<get_root()>

Return the root item of the graph.

=item C<has_item($item)>

Return true if the graph contains the item.

=item C<num_items($item)>

Return the number of items in the graph.

=item C<predecessors($item)>

Return the predecessor items of a given StreamGraph::View::Item.

=item C<remove ($item)>

Remove a StreamGraph::View::Item from the graph. Attach any
successor items that the item may have had to the items predecessor.

=item C<set_root ($item)>

Change the root item in the graph. An new graph is created with the
new root.

=item C<successors ($item)>

Return the successor items of a given StreamGraph::View::Item.

=item C<traverse_DFS ($item, $callback)>

Perform a depth-first traversal of the graph, repeatedly calling the
callback.

The traversal algorithm given in Graph.pm returns items in an
unpredictable order which causes the items in the mind map to be
placed differently each time the map is redrawn. So we use our own
method that returns items in the same order. Need to do something
about all these traversal routines.

=item C<traverse_BFS ($item, $callback)>

Perform a breadth-first traversal of the graph, repeatedly calling the
callback.

The traversal algorithm given in Graph.pm returns items in an
unpredictable order which causes the items in the mind map to be
placed differently each time the map is redrawn. So we use our own
method that returns items in the same order. Need to do something
about all these traversal routines.

=item C<traverse_preorder_edge($predecessor_item, $item, $callback)>

Perform a depth first traversal and pass back the predecessor item as
well as the item to the callback. Need to do something about all these
traversal routines.

=item C<traverse_postorder_edge($predecessor_item, $item, $callback)>

Perform a depth first traversal and pass back the predecessor item as
well as the item to the callback. Need to do something about all these
traversal routines.

=back
