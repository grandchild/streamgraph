package StreamGraph::Model::Node;

use warnings;
use strict;

use Moo;
use Digest::MD5 qw(md5_base64);
use Time::HiRes qw(gettimeofday);
use StreamGraph::Util qw(filterNodesForType);

use StreamGraph::View::Item;
extends "StreamGraph::Model::Saveable";


has name        => ( is=>"rw", default=>"item" );
has id          => ( is=>"ro", default=>sub{substr(md5_base64(gettimeofday),-6)});
has x           => ( is=>"rw", default=>0 );
has y           => ( is=>"rw", default=>0 );

has saveMembers => ( is=>"ro", default=>sub{[qw(name id x y outputType)]} );


sub isFilter { return shift->isa("StreamGraph::Model::Node::Filter"); }
sub isSubgraph { return shift->isa("StreamGraph::Model::Node::Subgraph"); }
sub isDataNode { my ($self) = @_; return $self->isFilter || $self->isSubgraph; }
sub isParameter { return shift->isa("StreamGraph::Model::Node::Parameter"); }
sub isComment { return shift->isa("StreamGraph::Model::Node::Comment"); }

sub is_split {
	my $self = shift;
	my $graph = shift;
	#print($self->{data}->name . " asking for successors with a " . ref($self->{graph}) . "\n");
	return $graph->successors($self) > 1;
}

sub is_join {
	my $self = shift;
	my $graph = shift;
	my @predecessors = $graph->predecessors($self);
	@predecessors = @{filterNodesForType(\@predecessors, "StreamGraph::Model::Node::Filter")};
	return @predecessors > 1;
}

sub resetId {
	my $self = shift;
	$self->{id} = substr(md5_base64(gettimeofday),-6);
}


1;
__END__

=head1 StreamGraph::Model::Node

Base class for Streamgraph graph objects

=head2 Properties

=over

=item C<$name> (String)

The display name of the node

=item C<$id> (String)

The random unique ID for this node.

=item C<$x> (Integer)

The horizontal position of this node in the editing area.

=item C<$y> (Integer)

The vertical position of this node in the editing area. Higher is further
down.

=back

=head3 Inherited from StreamGraph::Model::Saveable

=over

=item C<saveMembers>

=back

=head2 Methods

=over

=item C<StreamGraph::Model::Node-E<gt>new($name, $id, $x, $y)>

Create a StreamGraph::Model::Node.

=item C<isFilter()>

C<return> Boolean

Check if node is instance of subclass StreamGraph::Model::Node::Filter.


=item C<isSubgraph()>

C<return> Boolean

Check if node is instance of subclass StreamGraph::Model::Node::Subgraph.


=item C<isDataNode()>

C<return> Boolean

Check if node is instance of subclass StreamGraph::Model::Node::Filter or
StreamGraph::Model::Node::Subgraph.


=item C<isParameter()>

C<return> Boolean

Check if node is instance of subclass StreamGraph::Model::Node::Parameter.


=item C<isComment()>

C<return> Boolean

Check if node is instance of subclass StreamGraph::Model::Node::Comment.


=item C<is_split()>

C<return> Boolean

Check if node has more than one successor.


=item C<is_join()>

C<return> returnvalue

Check if node has more than one predecessor (only filters are considered).


=item C<resetId()>

C<return> new ID (String)

Set a new random ID for this node.

=back

=head3 Inherited from StreamGraph::Model::Saveable

=over

=item C<yaml_dump>

=back
