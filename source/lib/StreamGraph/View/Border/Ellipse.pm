package StreamGraph::View::Border::Ellipse;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gnome2::Canvas;

use StreamGraph::View::ArgUtils;

use base 'StreamGraph::View::Border';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    my %attributes = @_;

    args_valid(\%attributes, qw(group x y width height content width_pixels
				padding_pixels fill_color_gdk outline_color_gdk));

    arg_default($self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white'));

    arg_default($self, "outline_color_gdk", Gtk2::Gdk::Color->parse('gray'));

    $self->{border} = $self->border_get_image();

    $self->{content}->set(anchor=>'north-west');
    update($self);

    return $self;
}

sub update {
  my ($self) = @_;

  $self->{content}->update;
  my ($top, $left, $bottom, $right) = $self->border_insets();
  my $content_width = $self->{content}->get('width');
  my $content_height = $self->{content}->get('height');
  my $width_adjust = List::Util::max($content_width * 1.5, ($left + $right));
  my $height_adjust = List::Util::max($content_height * 1.5, ($top + $bottom));
  $self->{width} = $content_width + $width_adjust;
  $self->{height} = $content_height + $height_adjust;
}

sub border_get_image
{
    my $self = shift(@_);

    return Gnome2::Canvas::Item->new($self->{group}, 'Gnome2::Canvas::Ellipse',
				     'fill-color-gdk'=>$self->{fill_color_gdk},
				     'outline-color-gdk'=>$self->{outline_color_gdk});
}


sub border_insets
{
    my $self = shift(@_);

    my $min_inset = $self->{width_pixels} + $self->{padding_pixels};

    my $top = List::Util::max($min_inset, $self->{height} / 4);

    my $left = List::Util::max($min_inset, $self->{width} / 4);

    return ($top, $left, $top, $left);
}


sub border_set_x
{
    my ($self, $value) = @_;

    $self->{border}->set(x1=>$value);

    $self->{border}->set(x2=>$value + $self->{width});
}


sub border_set_y
{
    my ($self, $value) = @_;

    $self->{border}->set(y1=>$value);

    $self->{border}->set(y2=>$value + $self->{height});
}


sub border_set_width
{
    my ($self, $value) = @_;

    $self->{border}->set(x2=>$self->{x} + $value);
}


sub border_set_height
{
    my ($self, $value) = @_;

    $self->{border}->set(y2=>$self->{y} + $value);
}


sub border_set_param
{
    my ($self, $name, $value) = @_;

    $self->{border}->set($name=>$value);
}


1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Border::Ellipse

This module is internal to StreamGraph::View. It draws a
elliptical border for a StreamGraph::View::Item. This ellipse
is instantiated as part of the item creation process in
StreamGraph::View::ItemFactory.

=head2 Properties

=over

=item 'content' (StreamGraph::View::Content)

The content that is placed in the border.

=item 'x' (double)

The x-coordinate of the upper left corner of the ellipse bounding box.

=item 'y' (double)

The y-coordinate of the upper left corner of the ellipse bounding box.

=item 'width' (double)

The width of the ellipse bounding box.

=item 'height' (double)

The width of the ellipse bounding box.

=item 'width-pixels' (double)

The width of the ellipse (in pixels).

=item 'padding-pixels' (double)

The spacing between the ellipse border and the content (in pixels).

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, content=E<gt>$content, ...)>

Instantiate an elliptical border. You must provide the
Gnome2::Canvas::Group on which this border is to place itself. You
must also provide a content object.

=item C<border_get_image>

This method overrides the border_get_image method defined in
Border.pm. It instantiates a Gnome2::Canvas::Ellipse.

=item C<border_insets>

Return the C<($top, $left, $bottom, $right)> insets for an ellipse. This
defined the rectangle inside the ellipse in which content may be placed.
At the moment this algoriith is pretty crude. It will be improved.

=item C<border_set_x>

This method overrides the border_set_x method defined in Border.pm. It
sets the value of the border x1 coordinate, and adjusts the x2 value
so that the border retains it's width.

=item C<border_set_y>

This method overrides the border_set_y method defined in Border.pm. It
sets the value of the border y1 coordinate, and adjusts the y2 value
so that the border retains it's height.

=item C<border_set_width>

This method overrides the border_set_width method defined in
Border.pm. It sets the value of the border x2 coordinate to reflect
the new width.

=item C<border_set_height>

This method overrides the border_set_height method defined in
Border.pm. It sets the value of the border y2 coordinate to reflect
the new height.

=item C<border_set_param>

This method overrides the border_set_param method defined in
Border.pm. It sets parameters in the Gnome2::Canvas::Ellipse object
instantiated by this module.

=item C<update ()>

Sets height and width based on the content size.

=back
