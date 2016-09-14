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

=head1 StreamGraph::View

The StreamGraphView draws a graph on a Gnome2::Canvas.

The StreamGraphView is an extension of the Gnome2::Canvas which is a
Gtk2::Widget, so it can be placed in any Gtk2 container.

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

=over

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

Remove the item from the graph including all connections.

=item C<remove_connection($connection)>

Remove the connection from the graph.

=item C<set_root ($item)>

Change the root StreamGraph::View::Item in the underlying graph,
and revise the visible connections in the mind map.

=item C<println($str,$type)>

This methid prints a String on the terminal and if type is defined also shows a
image. Type is a string and has a format from Gtk2::Stock without gtk-.

=item C<connect($predecessor_item, $item, $connection_data)>

This method creates a new connection between two items.

=item C<deselect()>

This method deselects all items.

=back
