package StreamGraph::Model::Node::Filter;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";

has initCode            => ( is=>"rw", default=>"" );
has workCode            => ( is=>"rw", default=>"" );
has globalVariables     => ( is=>"rw", default=>"" );
has timesPush           => ( is=>"rw", default=>0 );
has timesPop            => ( is=>"rw", default=>0 );
has timesPeek           => ( is=>"rw", default=>0 );

has joinType            => ( is=>"rw", default=>"rr" );
has joinMultiplicities  => ( is=>"rw", default=>(0) );
has joinRRForAll        => ( is=>"rw", default=>1 );

has splitType           => ( is=>"rw", default=>"duplicate" );
has splitMultiplicities => ( is=>"rw", default=>(0) );
has splitRRForAll       => ( is=>"rw", default=>1 );

has inputType           => ( is=>"rw", default=>"void" );
has inputCount          => ( is=>"rw", default=>0 );

has outputType          => ( is=>"rw", default=>"void" );
has outputCount         => ( is=>"rw", default=>0 );

has saveMembers         => ( is=>"ro", default=>sub{[qw(
	name
	id
	x
	y
	initCode
	workCode
	globalVariables
	timesPush
	timesPop
	timesPeek
	joinType
	joinMultiplicities
	joinRRForAll
	splitType
	splitMultiplicities
	splitRRForAll
	inputType
	inputCount
	outputType
	outputCount
)]});

1;
