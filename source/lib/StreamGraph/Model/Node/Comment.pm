package StreamGraph::Model::Node::Comment;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";


has string      => ( is=>"rw", default=>"# comment" );

has saveMembers => ( is=>"ro", default=>sub{[qw(name id x y string)]});

1;

__END__

=head1 StreamGraph::Model::Node::Comment

The Implementation of comments in the StreamGraph view 
(a pretty uninteresting one if you ask me)

=head2 Properties

=over

=item C<string> (String)

The comment text.

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

=item C<StreamGraph::Model::Node::Comment-E<gt>new(string=>$string)>

Create a StreamGraph::Model::Node::Comment.

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