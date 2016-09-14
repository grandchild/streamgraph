package StreamGraph::Model::ConnectionData;

use warnings;
use strict;

use Moo;

use StreamGraph::View::Connection;

extends "StreamGraph::Model::Saveable";


# Multiplicities
has inputMult	=> ( is=>"rw", default=>1 );
has outputMult	=> ( is=>"rw", default=>1 );


has saveMembers => ( is=>"ro", default=>sub{[qw(inputMult outputMult)]} );


sub createCopy {
	my $self = shift;
	return StreamGraph::Model::ConnectionData->new(inputMult=>$self->inputMult, outputMult=>$self->outputMult);
}

1;

__END__

=head1 StreamGraph::Model::ConnectionData

The StreamGraph::Model::ConnectionData is the implementation of 
StreamIt's multiplicities for split-join connections.

=head2 Properties

=over

=item C<inputMult> (Integer)

The number of packages inputted from the split in one cycle.

=item C<outputMult> (Integer)

The number of packages inputted into the join in one cycle.


=item C<saveMembers> (list[String])

The properties which are saved, when a graph is saved to a file.

=back

=head3 Inherited from StreamGraph::Model::Saveable

None.

=head2 Methods

=over

=item C<StreamGraph::Model::ConnectionData-E<gt>new(inputMult=>$inputMult, outputMult=>$outputMult)>

Create a StreamGraph::Model::ConnectionData.

=item C<createCopy()>

C<return> A new StreamGraph::Model::ConnectionData with the exact same entries.

Copy the entries of the StreamGraph::Model::ConnectionData to a new  StreamGraph::Model::ConnectionData. 

=back

=head3 Inherited from StreamGraph::Model::Saveable

=over

=item C<yaml_dump>

=back
