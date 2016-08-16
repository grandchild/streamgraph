package StreamGraph::Model::Node::Subgraph;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";

has filepath            => ( is=>"rw", default=>"" );
has unsaved             => ( is=>"rw", default=>1 );

has joinType            => ( is=>"rw", default=>"roundrobin" );
has splitType           => ( is=>"rw", default=>"duplicate" );

has inputType           => ( is=>"rw", default=>"void" );
has inputCount          => ( is=>"rw", default=>0 );

has outputType          => ( is=>"rw", default=>"void" );
has outputCount         => ( is=>"rw", default=>0 );

has saveMembers         => ( is=>"ro", default=>sub{[qw(
	name
	id
	x
	y
	filepath
	joinType
	splitType
	inputType
	inputCount
	outputType
	outputCount
)]});


1;
