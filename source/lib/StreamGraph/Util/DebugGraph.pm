package StreamGraph::Util::DebugGraph;

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;
use GraphViz;

sub export_graph {
	my ($window,$view,$graph,$dir) = @_;

	my $g = GraphViz->new();
	my @V = $graph->{graph}->vertices();
	for my $item (@V) {
		$g->add_node( name_id($item->{data}) );
	}
	my @E = $graph->{graph}->edges();
	for my $edge (@E) {
		$g->add_edge( name_id(${$edge}[0]->{data}) , name_id(${$edge}[1]->{data}) );
	}
	$g->as_png($dir . "/view.png");

	if (defined $view->{DebugGraph}) { $view->{DebugGraph}->set_from_file($dir . "/view.png"); return; }
	my $dialog = Gtk2::Dialog->new(
		'DebugGraph',
		$window,
		[qw/destroy-with-parent/],
	);

	my $dbox = $dialog->vbox;
	my $image = Gtk2::Image->new_from_file ($dir . "/view.png");
	$view->{DebugGraph} = $image;
	$dbox->pack_start($image,FALSE,FALSE,0);
	$dbox->show_all();
	$dialog->signal_connect('delete-event'=>sub { undef $view->{DebugGraph}; $dialog->destroy(); });
	$dialog->show();
}

sub name_id {
	my ($data) = @_;
	return $data->{name} . "\n" . $data->{id};
}

1;
