package StreamGraph::Model::Pipeline;

use warnings;
use strict;

use Moo;

use StreamGraph::Model::CodeObject::SplitJoin;
use StreamGraph::Model::Node;
use StreamGraph::CodeGen;


sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete %args{first};
	my @codeObjects = [$node];
	my @successors = $node->successors;
	# TODO: if main: check if no successors!
	while (!isJoinNode($successors[0])) {
		if(isSplitNode($node)) {
			my $splitjoin = StreamGraph::Model::CodeObject::SplitJoin->new(first=>$node);
			push(@codeObjects, $splitjoin);
			push(@codeObjects, $splitjoin->next);
			$node = $splitjoin->next;
		} else {
			push(@codeObjects, $successors[0]);
			$node = $successors[0];
		}
		@successors = $node->successors;
	}
	$args{next} = $successors[0];
	$args{codeObjects} = @codeObjects;
	return \%args;
}

sub generate {
	my ($self) = @_;
	$self->name(StreamGraph::CodeGen::generatePipelineName);
	# TODO generate string
}