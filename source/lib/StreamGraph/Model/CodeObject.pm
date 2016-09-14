package StreamGraph::Model::CodeObject;

use warnings;
use strict;

use Moo;


has name       => ( is=>"rw", default=>"item" );
has outputType => ( is=>"rw" );

1;

__END__

=head1 StreamGraph::Model::CodeObject

The StreamGraph::Model::CodeObject class is a wrapper class for all 
implemented topological constructs of the StreamIt language and Parameters.

=head2 Properties

=over

=item C<name> (String)

The name of the topological construct.


=item C<outputType> (String)

The type of the output of the topological construct. 

=back

=head2 Methods

=over 

=item C<StreamGraph::Model::CodeObject-E<gt>new(name=E<gt>$name, outputType=E<gt>$outputType)>

Create a StreamGraph::Model::CodoeObject. Do not use CodeObject is an abstract class.

=back