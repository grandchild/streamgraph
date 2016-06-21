#!/usr/bin/env perl

use strict;
use warnings;

use lib "/home/jakob/dev/streamit/streamgraph/source/lib/";

# BEGIN {
# 	push @INC, '../..';
# }

use StreamGraph::View::Item;
use StreamGraph::Node;
use StreamGraph::NodeData;
use StreamGraph::Util::StringLoader;

print StreamGraph::Util::StringLoader::get("hey");

my $item = new StreamGraph::View::Item();
print $item->predecessors;



my $data = StreamGraph::NodeData->new(
		initCode => "init",
		workCode => "work",
		joinType => "void",
		joinMultiplicities => (1),
		joinRRForAll => 0,
		splitType => "rr",
		splitMultiplicities => (1),
		splitRRForAll => 0,
		inputType => "int",
		inputCount => 1,
		outputType => "void",
		outputCount => 0
	);

my $node = StreamGraph::Node->new(
		type => "filter",
		data => $data,
		viewItem => 0
	);

print $node->data->initCode . "\n";
print $node->data->workCode . "\n";
print $node->data->joinType . "\n";
print $node->data->joinMultiplicities . "\n";
print $node->data->joinRRForAll . "\n";
print $node->data->splitType . "\n";
print $node->data->splitMultiplicities . "\n";
print $node->data->splitRRForAll . "\n";
print $node->data->inputType . "\n";
print $node->data->inputCount . "\n";
print $node->data->outputType . "\n";
print $node->data->outputCount . "\n";
