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
		$g->add_node( name_id($item) );
	}
	my @E = $graph->{graph}->edges();
	for my $edge (@E) {
		$g->add_edge( name_id(${$edge}[0]) , name_id(${$edge}[1]) );
	}
	$g->as_png($dir . "/view.png");

	if (defined $view->{DebugGraph}) { $view->{DebugGraph}->set_from_file($dir . "/view.png"); return; }
	my $dialog = Gtk2::Dialog->new(
		'DebugGraph',
		$window,
		[qw/destroy-with-parent/],
	);

	my $dbox = $dialog->vbox;
	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($dir . "/view.png");
	$pixbuf = $pixbuf->scale_simple($pixbuf->get_width/2, $pixbuf->get_height/2, 'bilinear');
	my $image = Gtk2::Image->new_from_pixbuf($pixbuf);
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

__END__

=head1 StreamGraph::Util::DebugGraph

This module creates a GraphViz image of a graph and shows it in a dialog window.

=head2 Functions

=over

=item C<export_graph($window, $view,$graph, $dir)>

Creates a GraphViz image of a graph and shows it in a dialog window.

=item C<name_id($data)>

Creates a unique name from C<$data-E<gt>name> and C<$data-E<gt>id>.

=back
