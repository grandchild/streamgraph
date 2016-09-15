package StreamGraph::Util::ResultWindow;

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;

sub show_result {
	my ($window, $view, $result) = @_;

	if (defined $view->{resultBuffer}) { $view->{resultBuffer}->set_text($result); return; }
	my $dialog = Gtk2::Dialog->new(
		'Streamit Compile & Run Results',
		$window,
		[qw/destroy-with-parent/],
	);

	my $dbox = $dialog->vbox;
	my $resultBuffer = Gtk2::TextBuffer->new;
	$resultBuffer->set_text($result);
	my $resultView = Gtk2::TextView->new_with_buffer($resultBuffer);
	$resultView->modify_font(Gtk2::Pango::FontDescription->from_string("Deja Vu Sans Mono 8"));
	$resultView->modify_text('normal', Gtk2::Gdk::Color->parse('#333'));
	$resultView->modify_base('normal', Gtk2::Gdk::Color->parse('#fefefe'));
	$resultView->set_editable(0);
	$view->{resultBuffer} = $resultBuffer;
	my $scroller = Gtk2::ScrolledWindow->new();
	$scroller->add($resultView);
	$scroller->set_size_request(500,700);
	$dbox->pack_start($scroller,FALSE,FALSE,0);
	$dbox->show_all();
	$dialog->signal_connect('delete-event'=>sub { undef $view->{resultBuffer}; $dialog->destroy(); });
	$dialog->show();
}

1;
__END__

=head1 StreamGraph::Util::ResultWindow

This module shows the results of compiling and executing the generated
StreamIt code in a dialog window.

=head2 Functions

=over

=item C<show_result($window,$view,$result)>

Takes a String with the StreamIt run result and shows it in a dialog window.

=back
