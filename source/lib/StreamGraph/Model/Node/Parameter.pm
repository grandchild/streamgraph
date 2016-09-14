package StreamGraph::Model::Node::Parameter;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";

has outputType  => ( is=>"rw", default=>"void" );
has value       => ( is=>"rw", default=>0);

has saveMembers => (is=>"ro", default=>sub{[qw(name id x y outputType value)]});

1;
__END__

=head1 StreamGraph::Model::Node::Parameter

The parameter in the StreamGraph view have this data structure.

=head2 Properties

=over

=item C<outputType> (String)

The StreamIt type of the parameter.

=item C<value> (Var)

The value of the parameter.

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
 
=item C<StreamGraph::Model::Node::Parameter-E<gt>new($outputType, $value)>
 
Create a StreamGraph::Model::Node::Parameter.

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