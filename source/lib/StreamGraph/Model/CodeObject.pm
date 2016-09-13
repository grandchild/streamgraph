package StreamGraph::Model::CodeObject;

use warnings;
use strict;

use Moo;

use StreamGraph::Model::Node;


has name       => ( is=>"rw", default=>"item" );
has outputType => ( is=>"rw" );

1;

__END__

=head1 StreamGraph::Model::CodeObject

The StreamGraph::Model::CodeObject class is a wrapper class for all 
implemented topological constructs of the StreamIt language and Parameters.

=over

=item C<name> (String)

The name of the topological construct.


=item C<outputType> (String)

The type of the output of the topological construct. 

=back
