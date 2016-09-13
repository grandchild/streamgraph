package StreamGraph::View::Content::Picture;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gnome2::Canvas;

use constant MAX_HEIGHT => 700; # Pixels
use constant MAX_WIDTH  => 700; # Pixels

use StreamGraph::View::ArgUtils;
use StreamGraph::View::Content;

use base 'StreamGraph::View::Content';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    my %attributes = @_;

    args_valid(\%attributes, qw(group pixbuf x y width height));

    args_required(\%attributes, qw(group pixbuf));

    if (!$self->{pixbuf}->isa('Gtk2::Gdk::Pixbuf'))
    {
	croak "The pixbuf parameter must be a 'Gtk2::Gdk::Pixbuf'.\n";
    }

    my $width = $self->{pixbuf}->get_width();

    if ($width > MAX_WIDTH)
    {
	croak "The picture is too wide to be displayed.\n";
    }

    my $height = $self->{pixbuf}->get_height();

    if ($height > MAX_HEIGHT)
    {
	croak "The picture is too tall to be displayed.\n";
    }

    $self->{width}      = $width;

    $self->{height}     = $height;

    $self->{min_width}  = $width;

    $self->{min_height} = $height;

    $self->{image}      = $self->content_get_image();

    return $self;
}


# my $image = $content->content_get_image();

sub content_get_image
{
    my $self = shift(@_);

    return Gnome2::Canvas::Item->new($self->{group},
	      'Gnome2::Canvas::Pixbuf', pixbuf=>$self->{pixbuf});
}


# $self->content_set_x($value);

sub content_set_x
{
    my ($self, $value) = @_;

    $self->{image}->set(x=>$value);
}


# $self->content_set_y($value);

sub content_set_y
{
    my ($self, $value) = @_;

    $self->{image}->set(y=>$value);
}


# $self->content_set_width($value);

sub content_set_width
{
    my ($self, $value) = @_;

#    $self->{image}->set('width-set'=>$value);
}


# $self->content_set_height($value);

sub content_set_height
{
    my ($self, $value) = @_;

#    $self->{image}->set('height-set'=>$value);
}


# $self->content_set_param($param_name, $value);

sub content_set_param
{
    my ($self, $param_name, $value) = @_;

#    $self->{image}->set($param_name=>$value);
}



1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Content::Picture

Displays a picture on a Gnome2::Canvas. The image is not scaled or
clipped. The caller must prepare the image before it is passed to this
module.

=head2 Properties

=over

=item 'group' (Gnome2::Canvas::Group)

The canvas group on which this picture will be drawn.

=item 'pixbuf' (Gtk2::Gdk::Pixbuf)

The pixbuf that will be drawn on the canvas group.

=item 'x' (double)

The x-coordinate of the top left corner of the picture.

=item 'y' (double)

The y-coordinate of the top left corner of the picture.

=item 'width' (double)

The width of the picture.

=item 'height' (double)

The height of the picture.

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, pixbuf=E<gt>$pixbuf, ...)>

Instantiate a StreamGraph::View::Content::Picture content
item. You must give a Gnome2::Canvas::Group on which to place the
content item, and you must give a Gtk2::Gdk::Pixbuf that contains the
picture to be displayed.

=item C<content_get_image()>

Overrides the method in StreamGraph::View::Content. Returns the
Gnome2::Canvas::Pixbuf that is displayed on the canvas.

=item C<content_set_x()>

Overrides the method in StreamGraph::View::Content. Sets the
x-coordinate of the top left corner of the picture.

=item C<content_set_y()>

Overrides the method in StreamGraph::View::Content. Sets the
y-coordinate of the top left corner of the picture.

=item C<content_set_width()>

Overrides the method in StreamGraph::View::Content. Sets the width
of the picture.

=item C<content_set_height()>

Overrides the method in StreamGraph::View::Content. Sets the
height of the picture.

=item C<content_set_param()>

Overrides the method in StreamGraph::View::Content. Passes a
parameter to the Gnome2::Canvas::Pixbuf.

=back
