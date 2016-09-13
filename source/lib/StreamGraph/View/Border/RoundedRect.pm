package StreamGraph::View::Border::RoundedRect;

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

    args_valid(\%attributes, qw(group content x y width height radius width_pixels
				padding_pixels fill_color_gdk outline_color_gdk));

    arg_default($self, "radius", 10);

    arg_default($self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white'));

    arg_default($self, "outline_color_gdk", Gtk2::Gdk::Color->parse('gray'));

    $self->{content}->set(anchor=>'north-west');

    $self->{border} = $self->border_get_image();
    update($self);

    return $self;
}

sub update {
  my ($self) = @_;

  $self->{content}->update;
  my ($top, $left, $bottom, $right) = $self->border_insets();
  $self->{width}  = $self->{content}->get('width') + ($left + $right);
  $self->{height} = $self->{content}->get('height') + ($top + $bottom);
}

# $border->border_get_image();

sub border_get_image
{
    my $self = shift(@_);

    my $border = Gnome2::Canvas::Item->new($self->{group}, 'Gnome2::Canvas::Shape',
					   'fill-color-gdk'=>$self->{fill_color_gdk},
					   'outline-color-gdk'=>$self->{outline_color_gdk});

    $border->set_path_def(_rounded_rect($self));

    return $border;
}


# $border->border_set_x($value);

sub border_set_x
{
    my ($self, $value) = @_;

    $self->{border}->set_path_def(_rounded_rect($self));

    $self->{border}->request_update();
}


# $border->border_set_y($value);

sub border_set_y
{
    my ($self, $value) = @_;

    $self->{border}->set_path_def(_rounded_rect($self));

    $self->{border}->request_update();
}


# $border->border_set_width($value);

sub border_set_width
{
    my ($self, $value) = @_;

    $self->{border}->set_path_def(_rounded_rect($self));

    $self->{border}->request_update();
}


# $border->border_set_height($value);

sub border_set_height
{
    my ($self, $value) = @_;

    $self->{border}->set_path_def(_rounded_rect($self));

    $self->{border}->request_update();
}


# $border->border_set_param($name, $value);

sub border_set_param
{
    my ($self, $name, $value) = @_;

    $self->{border}->set($name=>$value);
}


sub _bezier
{
    my ($self, $corner, $x, $y) = @_;

    my $r = _radius($self);

    if ($corner eq 'upper_left')
    {
	return ($x,$y+$r, $x,$y+($r/2), $x+($r/2),$y, $x+$r, $y);
    }

    if ($corner eq 'upper_right')
    {
	return ($x-$r,$y, $x-($r/2),$y, $x,$y+($r/2), $x, $y+$r);
    }

    if ($corner eq 'lower_right')
    {
	return ($x,$y-$r, $x,$y-($r/2), $x-($r/2),$y, $x-$r, $y);
    }

    if ($corner eq 'lower_left')
    {
	return ($x+$r,$y, $x+($r/2),$y, $x,$y-($r/2), $x, $y-$r);
    }

    croak "Invalid corner argument: $corner\n";
}


sub _radius
{
    my $self = shift(@_);

    my $max_radius = List::Util::min($self->{width}, $self->{height}) * 3 / 8;

    return List::Util::max(0, List::Util::min($self->{radius}, $max_radius));
}


sub _rounded_rect
{
    my $self = shift(@_);

    my $x1 = $self->{x};

    my $y1 = $self->{y};

    my $x2 = $self->{x} + $self->{width};

    my $y2 = $self->{y} + $self->{height};

#    print "_rounded_rect, x: $self->{x}  y: $self->{y}  width: $self->{width}  height: $self->{height}\n";

    my @p = ();

    push @p, _bezier($self, 'upper_left',  $x1, $y1);

    push @p, _bezier($self, 'upper_right', $x2, $y1);

    push @p, _bezier($self, 'lower_right', $x2, $y2);

    push @p, _bezier($self, 'lower_left',  $x1, $y2);

    my $pathdef = Gnome2::Canvas::PathDef->new();

    $pathdef->moveto  ($p[0],  $p[1]);

    $pathdef->curveto ($p[2],  $p[3],  $p[4],  $p[5],  $p[6],  $p[7]);

    $pathdef->lineto  ($p[8],  $p[9]);

    $pathdef->curveto ($p[10], $p[11], $p[12], $p[13], $p[14], $p[15]);

    $pathdef->lineto  ($p[16], $p[17]);

    $pathdef->curveto ($p[18], $p[19], $p[20], $p[21], $p[22], $p[23]);

    $pathdef->lineto  ($p[24], $p[25]);

    $pathdef->curveto ($p[26], $p[27], $p[28], $p[29], $p[30], $p[31]);

    $pathdef->lineto  ($p[0],  $p[1]);

    # Close the path so that 'fill-color' will work.
    $pathdef->closepath_current;

    return $pathdef;
}



1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Border::RoundedRect

This module is internal to StreamGraph::View. It draws a rounded
rectangle border for a StreamGraph::View::Item. This rectangle is
instantiated as part of the item creation process in
StreamGraph::View::ItemFactory.

=head2 Properties

=over

=item 'content' (StreamGraph::View::Content)

The content to be placed in the rounded rectangle.

=item 'radius' (double)

The radius of the rounded rectangle corner (in pixels).

=item 'width-pixels' (double)

The width of the rounded rectangle corner (in pixels).

=item 'padding-pixels' (double)

The padding between the content and the border (in pixels).

=item 'x' (double)

The x-coordinate of the upper left corner of the border bounding box.

=item 'y' (double)

The y-coordinate of the upper left corner of the border bounding box.

=item 'width' (double)

The width of the border bounding box.

=item 'height' (double)

The height of the border bounding box.

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, content=E<gt>$content, ...)>

Instantiate a rounded rectangle border. You must provide the
Gnome2::Canvas::Group on which this border is to place itself. You
must also provide a content object, StreamGraph::View::Content.

=item C<border_get_image()>

This method overrides the border_get_image method defined in
Border.pm. It instantiates a Gnome2::Canvas::Shape.
.

=item C<border_set_x($value)>

This method overrides the border_set_x method defined in Border.pm. It
sets the value of the border x1 coordinate, and adjusts the x2 value
so that the border retains it's width.

=item C<border_set_y($value)>

This method overrides the border_set_y method defined in Border.pm. It
sets the value of the border y1 coordinate, and adjusts the y2 value
so that the border retains it's height.

=item C<border_set_width($value)>

This method overrides the border_set_width method defined in
Border.pm. It sets the value of the border x2 coordinate to reflect
the new width.

=item C<border_set_height($value)>

This method overrides the border_set_height method defined in
Border.pm. It sets the value of the border y2 coordinate to reflect
the new height.

=item C<border_set_param($name,$value)>

This method overrides the border_set_param method defined in
Border.pm. It sets parameters in the Gnome2::Canvas::Shape object
instantiated by this module.

=item C<update ()>

Sets height and width based on the content size.

=back
