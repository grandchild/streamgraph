package StreamGraph::View::HotSpot::Grip::RightAngle;

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

    args_valid(\%attributes, qw(item side enabled
				fill_color_gdk outline_color_gdk hotspot_color_gdk));

    arg_default($self, 'enabled', FALSE);

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

    # FIXME: Item is not defined...

    $self->{image}->set_path_def(_get_path_def($self));

    $self->{image}->request_update();
}


# my $image = $self->hotspot_get_image();

sub hotspot_get_image
{
    my $self = shift(@_);

    my $image = Gnome2::Canvas::Item->new($self->{item}, 'Gnome2::Canvas::Shape',
					  fill_color_gdk=>$self->{fill_color_gdk},
					  outline_color_gdk=>$self->{outline_color_gdk});

    $image->set_path_def(_get_path_def($self));

    return $image;
}


sub _get_path_def
{
    my $self = shift(@_);

    my $offset = 2;

    my $h = 10;

    my ($x, $y, $height, $width) = $self->{item}->get(qw(x y height width));

    my @p = ();

    if ($self->{side} eq 'top')
    {
	my $x0 = $x + $offset;

	my $y0 = $y + $height - $offset;

	@p = ($x0,$y0, $x0,$y0-$h, $x0+$h,$y0);
    }
    else # $self->{side} eq 'buttom'
    {
	my $x0 = $x + $width - $offset;

	my $y0 = $y + $height - $offset;

	@p = ($x0,$y0-$h, $x0-$h,$y0, $x0,$y0);
    }

    my $pathdef = Gnome2::Canvas::PathDef->new();

    $pathdef->moveto  ($p[0], $p[1]);

    $pathdef->lineto  ($p[2], $p[3]);

    $pathdef->lineto  ($p[4], $p[5]);

    $pathdef->lineto  ($p[0], $p[1]);

    $pathdef->closepath_current;

    return $pathdef;
}



1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::HotSpot::Grip::Lentil

Not used now.

A LentilGrip hotspot may be used to resize a
StreamGraph::View::Item. Normally, this grip will be used with an
StreamGraph::View::Border:RoundedRect.

=head2 Properties

=over

=item 'item' (StreamGraph::View::Item)

The item this grip is attached to.

=item 'enabled' (boolean)

If enabled, this grip is ready for action.

=item 'side' (string)

The side of the item on which to attach the grip. May be C<left> or C<right>.

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

=item C<new (item=E<gt>$item, side=E<gt>'top')>

Instantiates a hotspot. The following properties may be passed: item,
side, visible, enabled, fill_color_gdk, outline_color_gdk,
hotspot_color_gdk.

=item C<hotspot_adjust_event_handler>

Positions the grip at the lower left or right corner of the rectangle
defined by the insets. This will change for the next release.

=item C<hotspot_get_image>

Returns a right triangle shaped grip image.

=back
