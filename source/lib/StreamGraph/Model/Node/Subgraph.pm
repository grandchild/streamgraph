package StreamGraph::Model::Node::Subgraph;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";

has filepath            => ( is=>"rw", default=>"" );
has unsaved             => ( is=>"rw", default=>1 );
has visible             => ( is=>"rw", default=>1 );

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
	filepath
	visible
	joinType
	splitType
	inputType
	inputCount
	outputType
	outputCount
)]});


1;
__END__

=head1 StreamGraph::Model::Node::Subgraph

A node containing another graph.

=head2 Properties

=over

=item C<filepath> (String)

The path to the file in which the subgraph is saved.


=item C<unsaved> (Boolean)

Flag which specifies if the graph was never saved.


=item C<visible> (Boolean)

Flag which specifies if the View with the subgraph is open.


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

=item C<StreamGraph::Model::Node::Subgraph-E<gt>new(fields)>

Create a StreamGraph::Model::Node::Subgraph.

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
