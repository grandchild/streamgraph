package StreamGraph::Model::Saveable;

use strict;
use warnings;


use Moo;
use YAML qw(Bless Blessed);


has saveMembers => ( is=>"ro", default=>sub{[qw()]} );


sub yaml_dump {
	my $self = shift;
	Bless($self)->keys($self->saveMembers);
	return Blessed($self);
}

1;
__END__

=head1 StreamGraph::Model::Saveable

Base class for objects that should be serialized when saving the graph.

=head2 Properties

=over

=item C<saveMembers> (list[String])

A string list of members that should be saved.

=back

=head2 Methods

=over

=item C<StreamGraph::Model::Saveable-E<gt>new()>

Create a StreamGraph::Model::Saveable.

=item C<yaml_dump()>

C<return> a blessed YAML wrapped version of C<$self> with knowledge of members
to be saved and their order.

See documentation of YAML module for details.

=back
