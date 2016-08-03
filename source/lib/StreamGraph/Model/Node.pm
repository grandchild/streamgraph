package StreamGraph::Model::Node;

use warnings;
use strict;

use Moo;
use Digest::MD5 qw(md5_base64);
use Time::HiRes qw(gettimeofday);
use YAML qw(Bless Blessed);
use StreamGraph::Util qw(filterNodesForType);
use Data::Dump qw(dump);

use StreamGraph::View::Item;


has name        => ( is=>"rw", default=>"item" );
has id          => ( is=>"ro", default=>sub{substr(md5_base64(gettimeofday),-6)});
# has view        => ( is=>"ro", required=>1 );
has x           => ( is=>"rw", default=>0 );
has y           => ( is=>"rw", default=>0 );

has saveMembers => ( is=>"ro", default=>sub{[qw(name id x y outputType)]} );


sub isFilter { return shift->isa("StreamGraph::Model::Node::Filter"); }
sub isParameter { return shift->isa("StreamGraph::Model::Node::Parameter"); }
sub isComment { return shift->isa("StreamGraph::Model::Node::Comment"); }

sub yaml_dump {
	my $self = shift;
	Bless($self)->keys($self->saveMembers);
	return Blessed($self);
}

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

1;
