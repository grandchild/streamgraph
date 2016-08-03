package StreamGraph::View::Graph;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Graph::Directed;
use Data::Dump qw(dump);

use StreamGraph::Model::ConnectionData;


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
	my ($self, $item1, $item2, $inputMult, $outputMult, $inPrio, $outPrio) = @_;
	if ((!defined $item1) or (!defined $item2)) {
		croak "You must specify two items to connect.\n";
	}
	if (!$self->is_connectable($item1, $item2)) {
		return 0;
	}
	$self->add_vertex($item1) if (!$self->has_item($item1));
	$self->add_vertex($item2) if (!$self->has_item($item2));
	$self->{graph}->add_edge($item1, $item2);
	$inputMult = 1 if (!defined $inputMult);
	$outputMult = 1 if(!defined $outputMult);
	$inPrio = 1 if(!defined $inPrio);
	$outPrio = 1 if(!defined $outPrio);
	$self->set_edge_attribute($item1, $item2, 'data', 
		StreamGraph::Model::ConnectionData->new(inputMult=>$inputMult, outputMult=>$outputMult, 
			inputPrio=>$inPrio, outputPrio=>$outPrio));
	return 1;
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
	if ($item1->isFilter and $item2->isFilter) {
		if ($item1->{data}->outputType ne $item2->{data}->inputType) {
			print "Output type " . $item1->{data}->outputType .
					" does not match input type " . $item2->{data}->inputType . ".\n";
			return 0;
		}
	} elsif ($item1->isParameter and $item2->isFilter) {
	} else {
		print "You cannot connect these types of items: " .
			ref($item1->{data}) . " and " . ref($item2->{data}) . ".\n";
		return 0;
	}
	if ($self->is_predecessor($item1, $item2) || $item1 eq $item2) {
		print "Trying to form a cicle.\n";
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
			if ($ai->{data}->id eq $pi->{data}->id) {
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
		if ($pi->{data}->id eq $potential_predecessor->{data}->id) {
			return 1;
		}
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
		if ($self->predecessors($item, "StreamGraph::Model::Node::Filter") == 0) {
			push @sourceFilters, $item;
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


1; # Magic true value required at end of module
__END__

=head1 NAME

StreamGraph::View::Graph - Manages a directed graph.


=head1 VERSION

This document describes StreamGraph::View::Graph


=head1 SYNOPSIS

use StreamGraph::View::Graph;


=head1 DESCRIPTION

This is internal to StreamGraph::View. It's a wrapper around
Jarkko Heitaniemi's nice Graph module. This module is instantiated by
StreamGraph::View.

=head1 INTERFACE

=over

=item C<StreamGraph::View::Graph-E<gt>new()>

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

=head1 DIAGNOSTICS

=over

=item C<A root has already been defined. Use set_root to change the root>

The C<add()> method may only be used to set the root when the first
StreamGraph::View::Item is added to the graph.

=item C<You must remove the successors of this item prior to removing this item.>

The C<remove()> method will only remove items that have no successor
items.

=item C<You must pass in both the predecessor and the item you wish to remove.>

The C<remove()> method tries to remove an edge from the graph. You
need to specify the predecessor item because each
StreamGraph::View::Item may have more that one predecessor.

=back

=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
