package StreamGraph::Model::Parameter;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";

has outputType  => ( is=>"rw", default=>"void" );
has value       => ( is=>"rw", default=>0);

has saveMembers => (is=>"ro", default=>sub{[qw(name x y outputType)]});

1;
