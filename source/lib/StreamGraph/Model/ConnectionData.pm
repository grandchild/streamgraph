package StreamGraph::Model::ConnectionData;

use warnings;
use strict;

use Moo;

use StreamGraph::View::Connection;

extends "StreamGraph::Model::Saveable";


# Multiplicities
has inputMult	=> ( is=>"rw", default=>1 );
has outputMult	=> ( is=>"rw", default=>1 );

# Connection pin order
has priority	=> ( is=>"rw", default=>1 );

has saveMembers => ( is=>"ro", default=>sub{[qw(inputMult outputMult priority)]} );


sub createCopy {
	my $self = shift;
	return StreamGraph::Model::ConnectionData->new(inputMult=>$self->inputMult, outputMult=>$self->outputMult, 
			priority=>$self->priority);
}

1;
