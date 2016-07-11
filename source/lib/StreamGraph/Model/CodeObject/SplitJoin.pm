package StreamGraph::Model::SplitJoin;

use warnings;
use strict;

use Moo;

use StreamGraph::Model::CodeObject::Pipeline;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;


has split  => ( is=>"rw" );
has join   => ( is=>"rw" );


sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete %args{first};
	$args{split} = $node;
	my @codeObjects = [];
	my @successors = $node->successors;
	foreach my $s (@successors) {
		push(@codeObjects, StreamGraph::Model::CodeObject::Pipeline->new(first=>$s));
	}
	# potentially check discrepancies here!
	$args{join} = $codeObjects[0]->next;
	return \%args;
}


sub generate {
	my ($self) = @_;
	$self->name(StreamGraph::CodeGen::generatePipelineName);
	# TODO generate string
}