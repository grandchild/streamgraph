package StreamGraph::NodeData;

#use Gtk2::Ex::MindMapView::Item;



use Moo;
use warnings;
use strict;

has initCode            => ( is=>"rw", default=>"" );
has workCode            => ( is=>"rw", default=>"" );

has joinType            => ( is=>"rw" );
has joinMultiplicities  => ( is=>"rw" );
has joinRRForAll        => ( is=>"rw" );

has splitType           => ( is=>"rw" );
has splitMultiplicities => ( is=>"rw" );
has splitRRForAll       => ( is=>"rw" );

has inputType           => ( is=>"rw" );
has inputCount          => ( is=>"rw" );

has outputType          => ( is=>"rw" );
has outputCount         => ( is=>"rw" );

1;
