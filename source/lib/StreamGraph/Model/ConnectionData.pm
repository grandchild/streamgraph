package StreamGraph::Model::ConnectionData;

use warnings;
use strict;

use Moo;

use StreamGraph::View::Connection;

# Multiplicities
has inputMult	=> ( is=>"rw", default=>1 );
has outputMult	=> ( is=>"rw", default=>1 );
has inputPrio	=> ( is=>"rw", default=>1 );
has outputPrio	=> ( is=>"rw", default=>1 );

sub createCopy {
	my $self = shift;
	return StreamGraph::Model::ConnectionData->new(inputMult=>$self->inputMult, outputMult=>$self->outputMult, 
			inputPrio=>$self->inputPrio, outputPrio=>$self->outputPrio);
}

1;