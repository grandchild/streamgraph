package StreamGraph::View::HotSpot::Grip::Lentil;

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

    arg_default($self, 'radius', 10);

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

    my $o = 1;

    my $offset = 1;

    my $r = $self->{radius};

#    my ($top, $left, $bottom, $right) = $self->{item}->get_insets();

    my @p = ();

    if ($self->{side} eq 'top')
    {
	my $x = $self->{item}->get('x') + $offset;

	my $y = $self->{item}->get('y') + $self->{item}->get('height') - $offset;

	@p = ($x+$r-$o,$y-$o, $x+($r/2),$y, $x,$y-($r/2), $x+$o,$y-$r+$o, $x+($r/2),$y-$r, $x+$r,$y-($r/2));
    }
    else # $self->{side} eq 'buttom'
    {
	my $x = $self->{item}->get('x') + $self->{item}->get('width') - $offset;

	my $y = $self->{item}->get('y') + $self->{item}->get('height') - $offset;

	@p = ($x-$o,$y-$r+$o, $x,$y-($r/2), $x-($r/2),$y, $x-$r+$o,$y-$o, $x-$r,$y-($r/2), $x-($r/2),$y-$r);
    }

    my $pathdef = Gnome2::Canvas::PathDef->new();

    $pathdef->moveto  ($p[0], $p[1]);

    $pathdef->curveto ($p[2], $p[3], $p[4], $p[5], $p[6], $p[7]);

    $pathdef->curveto ($p[8], $p[9], $p[10], $p[11], $p[0], $p[1]);

    $pathdef->closepath_current;

    return $pathdef;
}



1; # Magic true value required at end of module
__END__

StreamGraph::View::HotSpot::Grip::Lentil

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

The side of the item on which to attach the grip. May be C<left> or
C<right>.

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

Instantiates a grip.

=item C<hotspot_adjust_event_handler>

Positions the grip at the lower left or right corner of the rectangle.

=item C<hotspot_get_image>

Returns the lentil shaped image to be drawn on the canvas.

=back
