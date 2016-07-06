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
	$view->{debugCodeBuffer} = $codeBuffer;
	$dbox->pack_start($codeView,FALSE,FALSE,0);
	$dbox->show_all();
	$dialog->signal_connect('delete-event'=>sub { undef $view->{debugCodeBuffer}; $dialog->destroy(); });
	$dialog->show();
}

sub name_id {
	my ($data) = @_;
	return $data->{name} . "\n" . $data->{id};
}

1;
