package StreamGraph::View::HotSpot::Toggle;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Glib ':constants';
use Gnome2::Canvas;
use StreamGraph::View::Connection;
use base 'StreamGraph::View::HotSpot';


# $self->hotspot_adjust_event_handler($item);

sub hotspot_adjust_event_handler {
		my ($self, $item) = @_;
}

sub hotspot_motion_notify {
	my ($self, $item, $event) = @_;
	if (defined $item->{view}->{toggleCon}) {
		my @coords = $event->coords;
		$coords[0] -= 5;
		$coords[1] -= 5;
		my $found = $item->{view}->get_item_at($coords[0], $coords[1]);
		if (defined $found->{connect_item}) {
			my ($isConnectable, $err) = $item->{view}->{graph}->connectable($item,$found->{connect_item});
			if ($isConnectable) {
				@coords = $found->{connect_item}->get_connection_point("top",$item->{view}->{toggleCon});
				$item->{view}->println("");
			} else {
				$item->{view}->println($err, "dialog-warning");
			}
		} else {
			# $coords[0] -= 5;
			# $coords[1] -= 5;
		}
		$item->{view}->{toggleCon}->{x2} = shift @coords;
		$item->{view}->{toggleCon}->{y2} = shift @coords;
		$item->{view}->{toggleCon}->_predecessor_connection();
	}
}

sub hotspot_enter_notify {
	my ($self, $item, $event) = @_;
}

# $self->hotspot_button_release($item, $event);
sub hotspot_button_release {
	my ($self, $item, $event) = @_;
	if ($self->{side} eq 'top' || !defined $item->{view}->{toggleCon}) { return; }
	my @coords = $event->coords;
	$self->end_connection;
	my $found = $item->{view}->get_item_at($coords[0], $coords[1]);
	if (defined $found->{connect_item}) {
		$item->{view}->connect($item, $found->{connect_item}) if $item ne $found->{connect_item};
	}
}

sub end_connection {
	my ($self) = @_;
	my $item = $self->{item};
	my @items = $item->{graph}->get_items;
	foreach my $i (@items) {
		$i->toggle_available(0);
	};
	$item->{view}->{toggleCon}->disconnect();
	$item->{view}->{toggleCon}->destroy();
	undef $item->{view}->{toggleCon};
}

sub hotspot_button_press {
	my ($self, $item, $event) = @_;
	if ($self->{side} eq 'top') { return; }
	my @items = $item->{graph}->all_non_predecessors($item);
	if ($item->isDataNode) {
		foreach my $i (@items) {
			my ($isConnectable, $err) = $item->{view}->{graph}->connectable($item,$i);
			$i->toggle_available(1) if $isConnectable;
		};
	}
	$item->{view}->{toggleCon} = Gnome2::Canvas::Item->new(
		$item->{view}->root,
		'StreamGraph::View::Connection',
		predecessor_item=>$item,
		arrows=>$item->{view}->{connection_arrows},
		width_pixels=>1,
		outline_color_gdk=>$item->{view}->{connection_colors_gdk}{default},
		fill_color=>'darkblue'
	);
}

1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::HotSpot::Toggle

The StreamGraph::View::HotSpot::Toggle defines toggle type
hotspots. This kind of hot spot is used to connect
StreamGraph::View::Items.

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a toggle type hotspot.

=item C<hotspot_adjust_event_handler>

Overrides method defined in StreamGraph::View::HotSpot. This
method sets the proper state of the toggle when a "hotspot_adjust"
event occurs.

=item C<hotspot_button_release ($item, $event)>

Overrides method defined in StreamGraph::View::HotSpot. This
method actually destroys temporal conencion line and creates
a new connection if a mouse is over a connectible item.

=item C<hotspot_button_press ($item, $event)>

Overrides method defined in StreamGraph::View::HotSpot. This
method actually creates a temporal connecion line and marks
all connectible items.

=item C<hotspot_motion_notify ($item, $event)>

Overrides method defined in StreamGraph::View::HotSpot. This
method actually set the coordinates of the temporal connection
arrow to the mouse coordinates. If the mouse is over a connectible
item, the coordinates are set to connection point of the item.

=back
