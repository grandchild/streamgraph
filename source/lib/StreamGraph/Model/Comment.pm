package StreamGraph::Model::Comment;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::Node";


has string      => ( is=>"rw", default=>"# comment" );

has saveMembers => ( is=>"ro", default=>sub{[qw(name id x y string)]});

1;
