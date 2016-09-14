package StreamGraph::Util::DebugCode;

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;

sub show_code {
	my ($window, $view, $code) = @_;

	if (defined $view->{debugCodeBuffer}) { $view->{debugCodeBuffer}->set_text($code); return; }
	my $dialog = Gtk2::Dialog->new(
		'Streamit Code',
		$window,
		[qw/destroy-with-parent/],
	);

	my $dbox = $dialog->vbox;
	my $codeBuffer = Gtk2::TextBuffer->new;
	$codeBuffer->set_text($code);
	my $codeView = Gtk2::TextView->new_with_buffer($codeBuffer);
	$codeView->modify_font(Gtk2::Pango::FontDescription->from_string("Deja Vu Sans Mono 8"));
	$codeView->modify_text('normal', Gtk2::Gdk::Color->parse('#f8f8f8'));
	$codeView->modify_base('normal', Gtk2::Gdk::Color->parse('#333'));
	$codeView->set_editable(0);
	$view->{debugCodeBuffer} = $codeBuffer;
	my $scroller = Gtk2::ScrolledWindow->new();
	$scroller->add($codeView);
	$scroller->set_size_request(500,700);
	$dbox->pack_start($scroller,FALSE,FALSE,0);
	$dbox->show_all();
	$dialog->signal_connect('delete-event'=>sub { undef $view->{debugCodeBuffer}; $dialog->destroy(); });
	$dialog->show();
}

1;

=head1 StreamGraph::Util::DebugCode

This modul shows the Streamit code in a dialog window.

=head2 Methods

=over

=item C<show_code> ($window,$view,$graph,$dir)

This method gets a String with the Streamit code and shows it in a dialog window.

=back
