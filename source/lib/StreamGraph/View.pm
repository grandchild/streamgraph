package StreamGraph::View;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Gnome2::Canvas;

use StreamGraph::View::Graph;
use StreamGraph::View::Connection;
use StreamGraph::Util::PropertyWindow;

use POSIX qw(DBL_MAX);

use Glib ':constants';

use Glib::Object::Subclass
	Gnome2::Canvas::,
	properties => [
			Glib::ParamSpec->string ('connection-arrows', 'arrows',
						'Type of arrow to display.', 'none', G_PARAM_READWRITE),

			Glib::ParamSpec->scalar ('connection-colors-gdk','connection_colors_gdk',
						'The colors of connections.', G_PARAM_READWRITE),
		   ]
	;


sub INIT_INSTANCE {
	my $self = shift(@_);
	$self->{graph} = StreamGraph::View::Graph->new();
	$self->{signals} = {}; # HoH
	$self->{connections} = {}; # HoA
	$self->{connection_colors_gdk} = {
		default => Gtk2::Gdk::Color->parse('gray'),
		data => Gtk2::Gdk::Color->parse('black'),
		parameter => Gtk2::Gdk::Color->parse('lightgray')
	};
	$self->{connection_arrows} = 'none';
	$self->{focusItem} = ();
	return $self;
}


sub SET_PROPERTY {
	my ($self, $pspec, $newval) = @_;
	my $param_name = $pspec->get_name();
	if ($param_name eq 'connection_arrows') {
		if (!grep { $_ eq $newval } qw(none one-way two-way)) {
			croak "You may only set the connection arrows " .
				 	"to: 'none', 'one-way', 'two-way'.\n"
		}
		$self->{connection_arrows} = $newval;
		return;
	}

	if ($param_name eq 'connection_colors_gdk') {
		if (!$newval->isa('Gtk2::Gdk::Color')) {
			croak "You may only set the connection color to " .
				"a Gtk2::Gdk::Color.\n";
		}
		$self->{connection_colors_gdk} = $newval;
		return;
	}
	$self->{$param_name} = $newval;
	return;
}


# $view->add_item($item);
# $view->add_item($predecessor_item, $item);
sub add_item {
	my ($self, $item) = @_;

	if (!$item->isa('StreamGraph::View::Item')) {
		croak "You may only add a StreamGraph::View::Item.\n";
	}

	if ($self->{graph}->has_item($item)) {
		croak "Item already exists in graph";
	}

	$self->{signals}{$item} =	$item->signal_connect('layout'=>sub { $self->layout(); });

	$item->set(graph=>$self->{graph});
	$item->set_view($self);
	$self->{connections}{$item} = [];
	$self->{graph}->add_vertex($item);
	$item->signal_emit('hotspot_adjust');
}


# $view->clear();
sub clear {
	my $self = shift(@_);
	return if (scalar $self->{graph}->num_items() == 0);
	my $root_item = $self->{graph}->get_root();
	my @successors = $self->{graph}->successors($root_item);
	foreach my $successor_item (@successors) {
		$self->{graph}->traverse_postorder_edge($root_item,
			$successor_item, sub { $self->remove_item($_[0], $_[1]); });
	}
	foreach my $item ($self->{graph}->get_items) {
		$self->remove_item($item);
	}
}


# $view->layout();
sub layout {
	my $self = shift(@_);
	if (scalar $self->{graph}->num_items()) {
	my $layout =
		StreamGraph::View::Layout::Balanced->new(graph=>$self->{graph});
		$layout->layout();
	}
}


# @predecessors = $view->predecessors($item);
sub predecessors {
	my ($self, $item) = @_;
	if (!$item->isa('StreamGraph::View::Item')) {
		croak "You may only get the predecessors of a " .
				"StreamGraph::View::Item.\n";
	}
	return $self->{graph}->predecessors($item);
}


# $view->remove_item($item);
sub remove_item {
	my ($self, $item) = @_;
	if (!$item->isa('StreamGraph::View::Item')) {
		croak "You may only remove a StreamGraph::View::Item.\n";
	}
	if (!defined $item || !$self->{graph}->has_item($item)) {
		croak "Item not defined\n";
	}
	# remove connections
	foreach my $side (qw(top down)) {
		while ($#{$item->{connections}{$side}}+1) {
			$self->remove_connection(${$item->{connections}{$side}}[0]);
		}
	}
	$self->{graph}->remove_vertex($item);
	if(defined $item->{gui}) {
		$item->{gui}->{view}->destroy;
		$item->{gui}->{window}->destroy;
	}
	$item->destroy();
}

# $view->remove_connection($predecessor_item, $item);
sub remove_connection {
	my ($self, $connection) = @_;
	my $predecessor_item = $connection->get('predecessor_item');
	my $item = $connection->get('item');
	$self->{graph}->remove_edge($predecessor_item,$item);
	$predecessor_item->remove_connection('down',$connection);
	$item->remove_connection('top',$connection);
	$connection->disconnect();
	$connection->destroy();
}

# $view->set_root($item);
sub set_root {
	my ($self, $item) = @_;
	if (!$item->isa('StreamGraph::View::Item')) {
		croak "You may only set the root to a StreamGraph::View::Item.\n";
	}

	if (!$self->{graph}->has_item($item)) {
		croak "You may only set the root to a StreamGraph::View::Item " .
			  "that's been added to the view.\n";
	}

	_clear_connections($self);
	$self->{graph}->set_root($item);
	my @successors = $self->{graph}->successors($item);
	foreach my $successor_item (@successors) {
		$self->{graph}->traverse_preorder_edge($item,
			$successor_item, sub { _add_connection($self, $_[0], $_[1]); });
	}
}


# @successors = $view->successors($item);
sub successors {
	my ($self, $item) = @_;
	if (!$item->isa('StreamGraph::View::Item')) {
		croak "You may only get the successors of a " .
			  "StreamGraph::View::Item.\n";
	}
	return $self->{graph}->successors($item);
}

sub println {
	my ($self,$str,$type) = @_;
	if (!defined $self->{terminal}) {return;}
	if (!defined $self->{terminal_scroller}) {return;}
	Glib::Source->remove($self->{printTimer}) if defined $self->{printTimer};
	my $buf = $self->{terminal}->get_buffer();
	$buf->set_text(" " . $str);
	if (!defined $type) {}
	else {
		$buf->insert_pixbuf($buf->get_start_iter,Gtk2::Button->new->render_icon('gtk-'.$type,'menu'));
	}
	$self->{terminal_scroller}->set_size_request(10, $str ne "" ? 25 : 0);
	$self->{printTimer} = Glib::Timeout->add(6000, sub {
		$self->println("");
		$self->{terminal_scroller}->set_size_request(10, 0);
		return FALSE;
	});
}

sub connect {
	my ($self, $predecessor_item, $item, $connection_data) = @_;
	my $color = $self->{connection_colors_gdk}{default};
	my $error = $self->{graph}->add_edge($predecessor_item, $item, $connection_data);
	if ($error ne "") {
		$self->println($error, "dialog-error");
		return 0;
	}
	my $type = $self->_connection_type($predecessor_item, $item);
	my $connection = Gnome2::Canvas::Item->new(
		$self->root,
		'StreamGraph::View::Connection',
		predecessor_item=>$predecessor_item,
		item=>$item,
		arrows=>$self->{connection_arrows},
		width_pixels=>1,
		outline_color_gdk=>$self->{connection_colors_gdk}{$type},
		fill_color=>'darkblue',
		type=>$type
	);
	if ($predecessor_item->isDataNode) {
		for my $side (qw(top down)){
			$connection->{toggles}{$side} = Gnome2::Canvas::Item->new(
				$side eq 'top' ? $predecessor_item : $item, 'Gnome2::Canvas::Ellipse',
				fill_color_gdk    => Gtk2::Gdk::Color->parse('white'),
				outline_color_gdk => Gtk2::Gdk::Color->parse('gray'),
			);
			$connection->{toggles}{$side}->signal_connect('event'=>sub {my ($item, $event) = @_; StreamGraph::Util::PropertyWindow::show_connection($connection) if $event->type eq 'button-press';});
		}
	}
	$item->add_connection('top',$connection);
	$predecessor_item->add_connection('down',$connection);
	$connection->signal_connect( event => sub { $connection->connection_event($self,pop @_); } );
	$self->_update_connection_depths();
	return 1;
}

sub _connection_type {
	my ($self, $predecessor_item, $item) = @_;
	if ($predecessor_item->isDataNode and $item->isDataNode) {
		return "data";
	} elsif ($predecessor_item->isParameter and $item->isDataNode) {
		return "parameter";
	} else {
		return "default";
	}
}

sub _update_connection_depths {
	my ($self) = @_;
	my @items = sort {$a->isDataNode ? -1 : 1} $self->{graph}->get_items;
	for my $item (@items) {
		for my $connection (@{$item->{connections}{down}}) {
			$connection->lower_to_bottom if $item->isDataNode;
			$connection->lower_to_bottom if $item->isParameter;
		}
	}
}

sub _clear_connections {
	my $self = shift(@_);
	my $root_item = $self->{graph}->get_root();
	my @successors = $self->{graph}->successors($root_item);
	foreach my $successor_item (@successors) {
	$self->{graph}->traverse_preorder_edge($root_item,
		 $successor_item, sub { _remove_connection($self, $_[0], $_[1]); });
	}
	$self->{connections} = undef;
}

sub deselect {
	my ($self) = @_;
	while ($#{$self->{focusItem}}+1) {
		my $it = shift @{$self->{focusItem}};
		$it->select(0);
	}
}

sub _remove_connection {
	my ($self, $predecessor_item, $item) = @_;
	my $index = 0;
	my @connections = @{$self->{connections}{$item}};
	foreach my $connection (@connections) {
		if ($connection->get('predecessor_item') == $predecessor_item) {
			$connection->disconnect();
			$connection->destroy();
			last;
		}
		$index++;
	}
	splice @{$self->{connections}{$item}}, $index, 1;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

StreamGraph::View - Display mind map or outline on a Gnome2::Canvas


=head1 VERSION

This document describes Gtk2::Ex::StreamGraphView version 0.0.1

=head1 HEIRARCHY

 Glib::Object
 +----Gtk2::Object
	  +----Gtk2::Widget
		   +----Gtk2::Container
				+----Gtk2::Layout
					 +----Gnome2::Canvas
						  +----Gtk2::Ex::StreamGraphView

=head1 SYNOPSIS

#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Gnome2::Canvas;

use Gtk2::Ex::StreamGraphView;
use StreamGraph::View::ItemFactory;

my $window   = Gtk2::Window->new();

my $scroller = Gtk2::ScrolledWindow->new();

my $view     = Gtk2::Ex::StreamGraphView->new(aa=>1);

my $factory  = StreamGraph::View::ItemFactory->new(view=>$view);

$view->set_scroll_region(-350,-325,350,325);

$scroller->add($view);

$window->signal_connect('destroy'=>sub { _closeapp($view); });

$window->set_default_size(900,350);

$window->add($scroller);

my $item1 = _text_item($factory, "Hello World!");

$view->add_item($item1);

my $item2 = _url_item($factory, "Google Search Engine", "http://www.google.com");

$view->add_item($item1, $item2);

my $item3 = _picture_item($factory, "./monalisa.jpeg");

$view->add_item($item1, $item3);

$view->layout();

$window->show_all();

Gtk2->main();

exit 0;


sub _closeapp
{
	my $view = shift(@_);

	$view->destroy();

	Gtk2->main_quit();

	return 0;
}


sub _text_item
{
	my ($factory, $text) = @_;

	my $item = $factory->create_item(border=>'StreamGraph::View::Border::RoundedRect',
					 content=>'StreamGraph::View::Content::EllipsisText',
					 text=>$text,
					 font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
					 hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'));

	$item->signal_connect(event=>\&_test_handler);

	return $item;
}


sub _url_item
{
	my ($factory, $text, $url) = @_;

	my $browser = '/usr/bin/firefox';

	my $item = $factory->create_item(border=>'StreamGraph::View::Border::RoundedRect',
					 content=>'StreamGraph::View::Content::Uri',
					 text=>$text, uri=>$url, browser=>$browser,
					 text_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
					 fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'));

	$item->signal_connect(event=>\&_test_handler);

	return $item;
}


sub _picture_item
{
	my ($factory, $file) = @_;

	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($file);

	my $item = $factory->create_item(border=>'StreamGraph::View::Border::Rectangle',
					 content=>'StreamGraph::View::Content::Picture',
					 pixbuf=>$pixbuf,
					 hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
					 fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'));

	$item->signal_connect(event=>\&_test_handler);

	return $item;
}

sub _test_handler
{
	my ($item, $event) = @_;

	my $event_type = $event->type;

	my @coords = $event->coords;

	print "Event, type: $event_type  coords: @coords\n";
}


1;


=head1 DESCRIPTION

The StreamGraphView draws a mind map (or outline) on a Gnome2::Canvas.

The StreamGraphView is an extension of the Gnome2::Canvas which is a
Gtk2::Widget, so it can be placed in any Gtk2 container.

This is an alpha version of the software, the functionality is
limited, and it contains BUGs. It should be used for experimentation
only at this time. Interfaces will change and so will properties.

Currently the mind map is limited to a balanced display of text
items. You may assign a font and change the color of the mind map
items.

See the C<examples> directory for examples of usage. You will find the
synopsis example there.

The following border types are supported:

StreamGraph::View::Border::RoundedRect - Displays a rounded rectangle border.

StreamGraph::View::Border::Rectangle - Displays a rectangular border.

StreamGraph::View::Border::Ellipse - Displays an elliptical border.

The following content types are supported:

StreamGraph::View::Content::EllipsisText - Displays text with optional ellipsis (...)

StreamGraph::View::Content::Picture - Displays a picture in a pixbuf.

StreamGraph::View::Content::Uri - Displays a URI.


=head1 INTERFACE

=head2 Properties

=over

=item 'aa' (boolean : readable / writable /construct-only)

The antialiasing mode of the canvas.

=item 'connection_colors_gdk' (Gtk2::Gdk::Color : readable / writable)

The default colors to apply to connection objects of various types as they are created.

=item 'connection_arrows' (string : readable / writable);

The type of arrow to use when creating a connection object. May be one
of: 'none', 'one-way', or 'two-way'.

=back

=head2 Methods

=over 4


=item C<new(aa=E<gt>1)>

Construct an anti-aliased canvas. Aliased canvases look just awful.


=item C<INIT_INSTANCE>

This subroutine is called by Glib::Object::Subclass as the object is
being instantiated. You should not call this subroutine
directly. Leave it alone.


=item C<SET_PROPERTY>

This subroutine is called by Glib::Object::Subclass to set a property
value. You should not call this subroutine directly. Leave it alone.


=item C<add_item ($item)>

Add the root item to the mind map. This is the node off of which
all other nodes are attached. The item must be a StreamGraph::View::Item.


=item C<add_item ($predecessor_item, $item)>

Add an item to the mind map. The item is linked to its predecessor
item. The item must be a StreamGraph::View::Item.


=item C<clear()>

Clear the items from the mind map.


=item C<layout()>

Layout the mind map. The map is redrawn on the canvas.


=item C<predecessors ($item)>

Returns an array of StreamGraph::View::Items that are the items
that link to the item argument you have specified. Each item in the
mind map may have zero or more predecessors.


=item C<remove_item ($item)>

Remove the root StreamGraph::View::Item from the mind map. This
item should not have any successors or predecessors.


=item C<remove_item ($predecessor_item, $item)>

Remove an item from the mind map. The StreamGraph::View::Item must
be a successor of predecessor StreamGraph::View::Item. You can
think of this as removing an edge from the graph underlying the mind
map. This routine makes sure that the visible connection on the canvas
is removed and that the item is removed from the underlying graph.

=item C<set_root ($item)>

Change the root StreamGraph::View::Item in the underlying graph,
and revise the visible connections in the mind map.

=back

=head1 DIAGNOSTICS

=over

=item C<You may only add a StreamGraph::View::Item>

You attempted to add something other than a
StreamGraph::View::Item to the mind map. The only items that may
be added to the Gtk2::Ex::StreamGraphView are of type
StreamGraph::View::Item.  Look at the
StreamGraph::View::ItemFactory to create items of type
StreamGraph::View::Item.

=item C<You may only add items that have a StreamGraph::View::Item
as predecessor>

You attempted to add a predecessor item that is something other than
a StreamGraph::View::Item to the mind map. The only items that may
be added to the Gtk2::Ex::StreamGraphView are of type
StreamGraph::View::Item.  Look at the
StreamGraph::View::ItemFactory to create items of type
StreamGraph::View::Item.


=item C<You may only get the predecessors of a StreamGraph::View::Item>

You attempted to get predecessors of an item that is something other than
a StreamGraph::View::Item.


=item C<You may only remove a StreamGraph::View::Item>

You attempted to remove something other than a
StreamGraph::View::Item from the mind map. The only items that may
be from to the Gtk2::Ex::StreamGraphView are of type
StreamGraph::View::Item.


=item C<You may only remove items that have a StreamGraph::View::Item
as predecessor>

You attempted to remove an item that does not have a
StreamGraph::View::Item as it's predecessor.


=item C<You must remove the successors of this item prior to removing this item.>

You attempted to remove an item that has successor items. A
StreamGraph::View::Item may only be removed once it's successors
have been removed.


=item C<You may only set the root to a StreamGraph::View::Item>

You attempted to set root of your Gtk2::Ex::StreamGraphView to an item
that is something other than a StreamGraph::View::Item.


=item C<You may only set the root to a StreamGraph::View::Item
that's been added to the view.>

You attempted to set root of your Gtk2::Ex::StreamGraphView to a
StreamGraph::View::Item that is not in the mind map. You must
first add the item to the mind map and then set it to be the root.


=item C<You may only get the successors of a StreamGraph::View::Item>

You attempted to get successors of an item that is something other
than a StreamGraph::View::Item.


=item C<You may only set the connection color to a Gtk2::Gdk::Color>

You must pass in a Gtk2::Gdk:Color in order to set the color.

=item C<You may only set the connection arrows to: 'none', 'one-way',
'two-way'>

You must pass in either 'none', 'one-way' or 'two-way' for the
connection arrow type.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Gtk2::Ex::StreamGraphView requires no configuration files or environment
variables.


=head1 DEPENDENCIES

The modules in Gtk2::Ex::StreamGraphView depend on the following CPAN
modules:

=over

=item Gnome2::Canvas

=item Graph

=back

Each of these modules has their own dependencies.

=head1 INCOMPATIBILITIES

This software is incompatible with older versions of
libgnomecanvas. See bugs below.


=head1 BUGS AND LIMITATIONS

As of the alpha release of this software the following are known bugs:

=over

On resize of a StreamGraph::View::Item if the cursor moves from
the item to the window frame, a 'button-release' event may not occur
and the layout will not be redrawn.

On older versions of libgnomecanvas, you may receive the following
error message when quitting your application or destroying the canvas:

"nomeCanvas-CRITICAL **: file gnome-canvas.c line 3698
(gnome_canvas_request_redraw): assertion 'GNOME_IS_CANVAS (canvas)'
failed during global destruction."

This is due to a bug in the finalization process of the canvas. It
attempts to redraw the screen during destruction. You get either an
assertion (as shown above) or a segfault.

=back

Please report any bugs or feature requests to
C<bug-gtk2-ex-StreamGraphView@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
