package StreamGraph::View::HotSpot::Grip::EllipseRound;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use StreamGraph::View::ArgUtils;

use Glib ':constants';

use Gnome2::Canvas;

use base 'StreamGraph::View::HotSpot::Grip';

sub new
{
    my ($class, @attributes) = @_;

    my $self = $class->SUPER::new(@attributes);

    my %attributes = @attributes;

    args_valid(\%attributes, qw(item side enabled radius
				fill_color_gdk outline_color_gdk hotspot_color_gdk));

    arg_default($self, 'enabled', FALSE);

    arg_default($self, 'radius', 3);

    arg_default($self, 'fill_color_gdk',    Gtk2::Gdk::Color->parse('white'));

    arg_default($self, 'outline_color_gdk', Gtk2::Gdk::Color->parse('gray'));

    arg_default($self, 'hotspot_color_gdk', Gtk2::Gdk::Color->parse('orange'));

    $self->{image}   = $self->hotspot_get_image();

    return $self;
}


# $self->hotspot_adjust_event_handler($item);

sub hotspot_adjust_event_handler
{
    my ($self, $item) = @_;

    my $offset = 1;

    my ($x, $y, $width, $height) = $self->{item}->get(qw(x y width height));

    my ($top, $left, $bottom, $right) = $self->{item}->get_insets();

    if ($self->{side} eq 'top')
    {
	_set_point($self, $x + $left, $y + $height - $bottom);
    }
    else
    {
	_set_point($self, $x + $width - $right, $y + $height - $bottom);
    }
}


# my $image = $self->hotspot_get_image();

sub hotspot_get_image
{
    my $self = shift(@_);

    return Gnome2::Canvas::Item->new($self->{item}, 'Gnome2::Canvas::Ellipse',
				     fill_color_gdk=>$self->{fill_color_gdk},
				     outline_color_gdk=>$self->{outline_color_gdk});
}


sub _set_point
{
    my ($self, $x, $y) = @_;

    my $radius = $self->{radius};

    $self->{image}->set(x1=>$x - $radius, y1=>$y - $radius,
			x2=>$x + $radius, y2=>$y + $radius);
}



1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::HotSpot::Grip::EllipseRound

Not used now.

The StreamGraph::View::HotSpot::Grip::EllipseRound is a round grip that
may be used to resize a StreamGraph::View::Border::Ellipse.

This special grip positions itself differently from the other grips.

=head2 Properties

=over

=item 'item' (StreamGraph::View::Item)

The item this grip is attached to.

=item 'enabled' (boolean)

If enabled, this grip is ready for action.

=item 'side' (string)

The side on which to attach the grip. May be C<left> or C<right>.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color with which to fill in the hotspot.

=item 'outline_color_gdk' (Gtk2::Gdk::Color)

The color with which to fill in the hotspot outline. Grips usually
have the outline set to the same color as the item fill color.

=item 'hotspot_color_gdk' (Gtk2::Gdk::Color)

The color of the hotspot once it is engaged. A hotspot becomes engaged
when the mouse is placed close to it.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a StreamGraph::View::HotSpot::Grip::EllipseRound hotspot.

=item C<hotspot_adjust_event_handler>

Positions the grip at the lower left or right corner of the rectangle
defined by the insets. This will change for the next release.

=item C<hotspot_get_image>

Returns a circle (Gnome2::Canvas::Ellipse) as grip image.

=back
