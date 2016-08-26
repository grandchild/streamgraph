package StreamGraph::Model::Node;

use warnings;
use strict;

use Moo;
use Digest::MD5 qw(md5_base64);
use Time::HiRes qw(gettimeofday);
use StreamGraph::Util qw(filterNodesForType);

use StreamGraph::View::Item;
extends "StreamGraph::Model::Saveable";


has name        => ( is=>"rw", default=>"item" );
has id          => ( is=>"ro", default=>sub{substr(md5_base64(gettimeofday),-6)});
has x           => ( is=>"rw", default=>0 );
has y           => ( is=>"rw", default=>0 );

has saveMembers => ( is=>"ro", default=>sub{[qw(name id x y outputType)]} );


sub isFilter { return shift->isa("StreamGraph::Model::Node::Filter"); }
sub isSubgraph { return shift->isa("StreamGraph::Model::Node::Subgraph"); }
sub isDataNode { my ($self) = @_; return $self->isFilter || $self->isSubgraph; }
sub isParameter { return shift->isa("StreamGraph::Model::Node::Parameter"); }
sub isComment { return shift->isa("StreamGraph::Model::Node::Comment"); }

sub is_split {
	my $self = shift;
	my $graph = shift;
	#print($self->{data}->name . " asking for successors with a " . ref($self->{graph}) . "\n");
	return $graph->successors($self) > 1;
}

sub is_join {
	my $self = shift;
	my $graph = shift;
	my @predecessors = $graph->predecessors($self);
	@predecessors = @{filterNodesForType(\@predecessors, "StreamGraph::Model::Node::Filter")};
	return @predecessors > 1;
}

sub resetId {
	my $self = shift;
	$self->{id} = substr(md5_base64(gettimeofday),-6);
}


1;
