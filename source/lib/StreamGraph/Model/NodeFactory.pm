package StreamGraph::Model::NodeFactory;

use warnings;
use strict;

use Moo;

use StreamGraph::View::Item;
use StreamGraph::View::ItemFactory;
use StreamGraph::Model::Filter;
use StreamGraph::Model::Parameter;
use StreamGraph::Model::Comment;

# has view            => ( is=>"ro", required=>1 );

sub createNode {
	my ($self, @attributes) = @_;
	my %attributes = @attributes;
	my $attributes = @attributes;
	my $type = delete $attributes{type};
	return $type->new(%attributes);
}

1;
