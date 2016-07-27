package StreamGraph::Model::ConnectionData;

use warnings;
use strict;

use Moo;

use StreamGraph::View::Connection;


has inputMultiplicity	=> ( is=>"rw", default=>1 );
has outputMultiplicity	=> ( is=>"rw", default=>1 );

1;