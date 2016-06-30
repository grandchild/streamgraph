package StreamGraph::Util::DebugGraph;

use strict;
use GraphViz;

sub export_graph {
	my ($graph) = @_;
	my $g = GraphViz->new();
	my @V = $graph->{graph}->vertices();
	for my $item (@V) {
		$g->add_node($item->{data}->{name});
	}
	my @E = $graph->{graph}->edges();
	for my $edge (@E) {
		$g->add_edge(${$edge}[0]->{data}->{name},${$edge}[1]->{data}->{name});
	}
	$g->as_png("view.png");
}

1;
