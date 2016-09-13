package StreamGraph::View::HotSpot::Toggle::Round;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Glib ':constants';
use Gnome2::Canvas;
use constant IMAGE_RADIUS_NORMAL => 3;
use constant IMAGE_RADIUS_AVAILABLE => 5;

use StreamGraph::View::ArgUtils;
use base 'StreamGraph::View::HotSpot::Toggle';


sub new {
	my ( $class, @attributes ) = @_;
	my $self = $class->SUPER::new(@attributes);
	my %attributes = @attributes;
	args_valid(
		\%attributes, qw(item side enabled radius
			fill_color_gdk outline_color_gdk hotspot_color_gdk)
	);
	arg_default( $self, 'radius', IMAGE_RADIUS_NORMAL );
	arg_default( $self, 'enabled', TRUE );
	arg_default( $self, 'fill_color_gdk', Gtk2::Gdk::Color->parse('white') );
	arg_default( $self, 'outline_color_gdk', Gtk2::Gdk::Color->parse('gray') );
	arg_default( $self, 'hotspot_color_gdk', Gtk2::Gdk::Color->parse('orange') );
	$self->{image} = $self->hotspot_get_image();
	if ( !$self->{enabled} ) {
		$self->{image}->hide();
	}
	return $self;
}

# $self->hotspot_adjust_event_handler($item);
sub hotspot_adjust_event_handler {
	my ( $self, $item ) = @_;
	$self->SUPER::hotspot_adjust_event_handler($item);
	my ( $x, $y ) = $self->{item}->get_connection_point( $self->{side} );
	$self->{image}->set(
		x1 => $x - $self->{radius},
		y1 => $y - $self->{radius},
		x2 => $x + $self->{radius},
		y2 => $y + $self->{radius}
	);
}

sub hotspot_toggle_available {
	my ( $self, $item, $available ) = @_;
	$self->{radius} = $available ? IMAGE_RADIUS_AVAILABLE : IMAGE_RADIUS_NORMAL;
	$self->hotspot_adjust_event_handler($item);
}

# my $image = $self->hotspot_get_image();
sub hotspot_get_image {
	my $self = shift(@_);
	my $ellipse = Gnome2::Canvas::Item->new(
		$self->{item}, 'Gnome2::Canvas::Ellipse',
		fill_color_gdk    => $self->{fill_color_gdk},
		outline_color_gdk => $self->{outline_color_gdk}
	);
	$ellipse->{toggle} = $self;
	return $ellipse;
}

1;    # Magic true value required at end of module
__END__

=head1 StreamGraph::View::ItemHotSpot

Four StreamGraph::View::ItemHotSpots are created for each
StreamGraph::View::Item. The hotspots are areas on the mind map,
that when clicked, cause an action to be performed on an item. These
hotspots allow the user to expand/collapse the items in the mind map,
or to resize an item.

=head2 Properties

=over

=item C<item> (StreamGraph::View::Item)

The item that this hotspot belongs to.

=item C<enabled>

If true, the toggle is receiving events and may act on them. Otherwise
it is not receiving events.

=item C<fill_color_gdk> (Gtk2::Gdk::Color)

The color with which to fill the toggle.

=item C<outline_color_gdk> (Gtk2::Gdk::Color)

The color with which to fill in the hotspot outline. Toggles normally
have a visible outline, while grips usually have the outline set to
the same color as the item fill color.

=item C<hotspot_color_gdk> (Gtk2::Gdk::Color)

The color of the hotspot once it is engaged. A hotspot becomes engaged
when the mouse is placed close to it.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a hotspot. The following properties may be passed: item,
enabled, fill_color_gdk, outline_color_gdk, hotspot_color_gdk.

=item C<hotspot_adjust_event_handler>

Overrides method defined in StreamGraph::View::HotSpot. This
method sets the proper state of the toggle when a "hotspot_adjust"
event occurs.

=item C<hotspot_get_image>

Overrides method defined in StreamGraph::View::HotSpot. Returns a
circle (Gnome2::Canvas::Ellipse) image.

=back
