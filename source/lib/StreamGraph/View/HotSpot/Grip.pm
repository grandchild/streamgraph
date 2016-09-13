package StreamGraph::View::HotSpot::Grip;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Glib ':constants';

use Gnome2::Canvas;

use base 'StreamGraph::View::HotSpot';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    $self->{x}       = 0;

    $self->{y}       = 0;

    $self->{x_prime} = 0;

    $self->{y_prime} = 0;

    return $self;
}


# $self->hotspot_button_press($item, $event);

sub hotspot_button_press
{
    my ($self, $item, $event) = @_;

    my @coords = $self->{item}->w2i($event->coords); # cursor position.

    $self->{x_prime} = $coords[0];

    $self->{y_prime} = $coords[1];
}


# $self->hotspot_button_release($item, $event);

sub hotspot_button_release
{
    my ($self, $item, $event) = @_;

    $self->{item}->signal_emit('layout');
}


# $self->hotspot_motion_notify($item, $event);

sub hotspot_motion_notify
{
    my ($self, $item, $event) = @_;

    my @coords = $self->{item}->w2i($event->coords); # cursor position.

    $self->{x} = $coords[0];

    $self->{y} = $coords[1];

    $self->{item}->resize($self->{side}, ($self->{x} - $self->{x_prime}), ($self->{y} - $self->{y_prime}));

    $self->{x_prime} = $self->{x};

    $self->{y_prime} = $self->{y};
}



1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::HotSpot::Grip

Not used now.

The StreamGraph::View::HotSpot::Grip defined grip type hotspots. This
kind of hot spot is used to resize StreamGraph::View::Items.

=head2 Properties

=over

=item 'x' (double)

The x-coordinate of the mouse location when resizing an item.

=item 'y' (double)

The y-coordinate of the mouse location when resizing an item.

=item 'x_prime' (double)

The x-coordinate of the previous mouse location when resizing an item.

=item 'y_prime' (double)

The y-coordinate of the previous mouse location when resizing an item.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a grip type hotspot.

=item C<hotspot_button_press>

Overrides method defined in StreamGraph::View::HotSpot. This
method records the position of the cursor when the mouse is first
pressed.

=item C<hotspot_button_release>

Overrides method defined in StreamGraph::View::HotSpot. This
method signals that the mind map should be redrawn.

=item C<hotspot_motion_notify>

Overrides method defined in StreamGraph::View::HotSpot. This
method actually resizes the StreamGraph::View::Item.

=back
