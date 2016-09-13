package StreamGraph::View::Border;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;

use Gnome2::Canvas;

use StreamGraph::View::ArgUtils;

sub new
{
    my $class = shift(@_);

    my $self = {};

    bless $self, $class;

    my %attributes = @_;

    args_required(\%attributes, qw(group content));

    args_store($self, \%attributes);

    if (!$self->{group}->isa('Gnome2::Canvas::Group'))
    {
	croak "Unexpected value for group. Valid is: Gnome2::Canvas::Group\n";
    }

    if (!$self->{content}->isa('StreamGraph::View::Content'))
    {
	croak "Unexpected value for content. Valid is: " .
  	      "StreamGraph::View::Content\n";
    }

    arg_default($self, "x", 0);

    arg_default($self, "y", 0);

    arg_default($self, "width", 0);

    arg_default($self, "height", 0);

    arg_default($self, "width_pixels", 2);

    arg_default($self, "padding_pixels", 5);

    return $self;
}


# my $image = $border->border_get_image();

sub border_get_image
{
    my $self = shift(@_);

    croak "You must supply a border image by overriding 'border_get_image'.\n";
}

sub select {
	my ($self,$switch) = @_;
	if ($switch) {
    $self->{border}->set('fill-color-gdk' =>  Gtk2::Gdk::Color->parse('lightblue'));
  } else {
    $self->{border}->set('fill-color-gdk' =>  Gtk2::Gdk::Color->parse('white'));
  }
}

# $self->border_set_x($value);

sub border_set_x
{
    my ($self, $value) = @_;

    croak "You must set the border x coordinate by overriding 'border_set_x'.\n";
}


# $self->border_set_y($value);

sub border_set_y
{
    my ($self, $value) = @_;

    croak "You must set the border y coordinate by overriding 'border_set_y'.\n";
}


# $self->border_set_width($value);

sub border_set_width
{
    my ($self, $value) = @_;

    croak "You must set the border width by overriding 'border_set_width'.\n";
}


# $self->border_set_height($value);

sub border_set_height
{
    my ($self, $value) = @_;

    croak "You must set the border height by overriding 'border_set_height'.\n";
}


# $self->border_set_param($param_name, $value);

sub border_set_param
{
    my ($self, $param_name, $value) = @_;
}


# my ($top, $left, $down, $right) = $self->border_insets();

sub border_insets
{
    my $self = shift(@_);

    my ($width, $padding) = $self->get( qw(width_pixels padding_pixels));

    my $inset = $width + $padding;

    return ($inset, $inset, $inset, $inset);
}


# my $value = $border->get(qw(x y width height));

sub get
{
    my $self = shift(@_);

    return undef if (scalar @_ == 0);

    return _get($self,shift(@_)) if (scalar @_ == 1);

    my @values = ();

    foreach my $param_name (@_) { push @values, _get($self, $param_name); }

    return @values;
}


# $border->reparent($group);

sub reparent
{
    my ($self, $group) = @_;

    $self->{group} = $group;

    $self->{border}->reparent($group);
}


# $border->set(x=>0, y=>10, width=>20, height=>30);

sub set
{
  my $self = shift(@_);
  my %attributes = @_;
  foreach my $param_name (keys %attributes) {
    my $value = $attributes{$param_name};

  	if ($param_name eq 'x')	{
	    $self->{x} = $value;
	    $self->{content}->set(x=>$value + ($self->border_insets())[1]);
	    $self->border_set_x($value);
	    next;
  	}

    if ($param_name eq 'y') {
      $self->{y} = $value;
      $self->{content}->set(y=>$value + ($self->border_insets())[0]);
      $self->border_set_y($value);
      next;
    }

  	if ($param_name eq 'width') {
	    my $min_width = $self->{content}->get_min_width();
	    my ($top, $left, $down, $right) = $self->border_insets();
	    my $width = List::Util::max($value, $min_width + ($left + $right));
	    $self->{width} = $width;
	    $self->{content}->set(width=>($width - ($left + $right)));
	    $self->border_set_width($width);
	    next;
  	}

  	if ($param_name eq 'height')
  	{
	    my $min_height = $self->{content}->get_min_height();
	    my ($top, $left, $down, $right) = $self->border_insets();
	    my $height = List::Util::max($value, $min_height + ($top + $down));
	    $self->{height} = $height;
	    $self->{content}->set(height=>($height - ($top + $down)));
	    $self->border_set_height($height);
	    next;
  	}

    $self->border_set_param($param_name=>$value);
  }
}


# my ($x, $y) = $border->get_connection_point('left');

sub get_connection_point
{
  my ($self, $side, $num, $num_total) = @_;
  $num_total--;
  my $x = int $self->{x} + 10 + ($num_total == 0 ? 0 : $num * ( ($self->{width}-20) / $num_total) );
  my $y = ($side eq 'top') ? ($self->{y}) : ($self->{y} + $self->{height});
  return ($x, $y);
}


sub get_min_height
{
    my $self = shift(@_);

    my ($top, $left, $down, $right) = $self->border_insets();

    return ($self->{content}->get_min_height() + ($top + $down));
}


sub get_min_width
{
    my $self = shift(@_);

    my ($top, $left, $down, $right) = $self->border_insets();

    return ($self->{content}->get_min_width() + ($left + $right));
}


sub _get
{
    my ($self, $param_name) = @_;

    my $value = $self->{$param_name};

    croak "Undefined value for key $param_name.\n" if (!defined $value);

    return $value;
}



1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Border

This module is internal to StreamGraph::View. It is the base class
for objects that draw borders and offers several classes that are to
be overidden.

=head2 Properties

=over

=item 'content' (StreamGraph::View::Content)

The content to be placed in this border.

=item 'group' (Gnome2::Canvas::Group)

The canvas group on which the border will be drawn.

=item 'x' (double)

The x-coordinate of the upper left corner of the bounding box of this
border.

=item 'y' (double)

The y-coordinate of the upper left corner of the bounding box of this
border.

=item 'width' (double)

The width of the bounding box of this border.

=item 'height' (double)

The height of the bounding box of this border.

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, content=E<gt>$content, ...)>

Instantiate a border. You must provide the Gnome2::Canvas::Group on
which this border is to place itself, and also a content object,
StreamGraph::View::Content.

=item C<border_get_image()>

This method must be overridden. You defined the image for your border
here.

=item C<border_insets ()>

Return the C<($top,$left,$down,$right)> insets for the border. This
method may be overridden.

=item C<border_set_x($value)>

This method must be overridden. It sets the value of the border x
coordinate.

=item C<border_set_y($value)>

This method must be overridden. It sets the value of the border y
coordinate.

=item C<border_set_width($value)>

This method must be overridden. It sets the value of the border width.

=item C<border_set_height($value)>

This method must be overridden. It sets the value of the border
height.

=item C<border_set_param($name, $value)>

This method may optionally be overridden to pass values to the object
created by border_get_image.

=item C<get($name)>

Returns the value of a property.

=item C<get_min_width()>

Returns the minimum height of the border.

=item C<get_min_height()>

Returns the minimum width of the border.

=item C<get_connection_point($side)>

Returns the point on the border that is used to draw the connection
to other StreamGraph::View::Items.

Items may connect to the left or right hand side of a border. The
C<$side> may have the value 'left' or 'right'.

This method is called by StreamGraph::View::Connection.

=item C<reparent($group)>

When a border is passed to a StreamGraph::View::Item, the item
places the border in it's own Gnome2::Canvas::Group using this
reparent method.

=item C<set(property=E<gt>$value>

Sets the value of a property. See the properties list above.

=back
