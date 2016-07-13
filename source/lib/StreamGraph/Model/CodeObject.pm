package StreamGraph::Model::CodeObject;

use warnings;
use strict;

use Moo;

use StreamGraph::Model::Node;


has name         => ( is=>"rw", default=>"item" );
has next         => ( is=>"rw" );
has code 		 => ( is=>"rw" );
has codeObjects  => ( is=>"rw", default=>sub{[]} );
has inputType	 => ( is=>"rw" );
has outputType   => ( is=>"rw" );

1;