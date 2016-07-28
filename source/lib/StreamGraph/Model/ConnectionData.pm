package StreamGraph::Model::ConnectionData;

use warnings;
use strict;

use Moo;

use StreamGraph::View::Connection;

# Multiplicities
has inputMult	=> ( is=>"rw", default=>1 );
has outputMult	=> ( is=>"rw", default=>1 );

1;