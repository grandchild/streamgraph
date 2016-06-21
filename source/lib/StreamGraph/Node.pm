package StreamGraph::Node;

# use Gtk2::Ex::MindMapView::Item;

use Moo;
use warnings;
use strict;

has type     => ( is => 'ro' );
has data     => ( is => 'ro' );
has viewItem => ( is => 'ro' );

1;
