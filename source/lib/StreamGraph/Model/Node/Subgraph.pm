package StreamGraph::Model::Node::Subgraph;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";

has filepath            => ( is=>"rw", default=>"" );
has unsaved             => ( is=>"rw", default=>1 );
has visible             => ( is=>"rw", default=>1 );
has graph               => ( is=>"rw" );

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
	visible
	joinType
	splitType
	inputType
	inputCount
	outputType
	outputCount
)]});


1;
__END__

=head1 StreamGraph::Model::Node::Subgraph

A node containing another graph.

=head2 Properties

=over

=item C<Name> (Type)

Description

=back

=head2 Methods

=over

=item C<StreamGraph::Model::Node::Subgraph-E<gt>new(fields)>

Create a StreamGraph::Model::Node::Subgraph.

=back
