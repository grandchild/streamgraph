package StreamGraph::Model::CodeObject::Parameter;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use Data::Dump qw(dump);

has associatedParameter	=> ( is=>"rw" );
has value				=> ( is=>"rw" );

sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete $args{node};
	$node->{'_generated'} = 1;
	$args{associatedParameter} = $node;
	$args{outputType} = $node->outputType;
	$args{value} = $node->value;
	$args{name} = $node->name;
	return \%args;
}


sub updateValues {
	my $self = shift;
	if(!defined($self)){
		return;
	}
	$self->name($self->associatedParameter->name);
	$self->value($self->associatedParameter->value);
	$self->outputType($self->associatedParameter->outputType);
}

1;

__END__

=head1 StreamGraph::Model::CodeObject::Parameter

Implements parameters for usage in the code generation.

=head2 Properties

=over

=item C<associatedParameter> (StreamGraph::Model::Node::Parameter)

The node in the graph which represents the parameter.


=item C<value> (Var)

The value of the parameter.

=back


=head3 Inherited from StreamGraph::Model::CodeObject

See the documentation of StreamGraph::Model::CodeObject for descriptions.

=over

=item C<name> (String)

=item C<outputType> (String)

=back


=head2 Methods

=over

=item C<StreamGraph::Model::CodeObject::Parameter-E<gt>new($node)>

Create a StreamGraph::Model::CodeObject::Parameter.

=item C<updateValues()>

Updates the values of the codeObject with those of the associated parameter.

=back

=head3 Inherited from StreamGraph::Model::CodeObject

None.