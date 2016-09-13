package StreamGraph::View::Content::EllipsisText;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use constant MAX_WIDTH=>300; # pixels.
use constant MAX_HEIGHT=>300; # pixels.

use List::Util;

use Gnome2::Canvas;

use StreamGraph::View::ArgUtils;
use StreamGraph::View::Content;

use base 'StreamGraph::View::Content';

sub new
{
    my $class = shift(@_);

    my $self = $class->SUPER::new(@_);

    my %attributes = @_;

#    args_valid(\%attributes, qw(group x y width height text text_color_gdk font_desc));

    args_required(\%attributes, qw(group text));

    my $canvas = $self->{group}->canvas();

    arg_default($self, "font_desc", Gtk2::Pango::FontDescription->from_string('Ariel Normal 10'));

    arg_default($self, "text_color_gdk", Gtk2::Gdk::Color->parse('black'));

    $self->{image}      = $self->content_get_image();

    # Normally the text is made to fit the space determined by the
    # width and height properties. On instantiation, the initial size
    # of the text is determined by the text itself and the MAX_WIDTH.
    update($self);

#    print "EllipsisText, new, height: $self->{height}  width: $self->{width}\n";

    return $self;
}

sub update {
  my ($self) = @_;

  $self->{min_height} = $self->{image}->get('text-height');
  $self->{height}     = $self->{image}->get('text-height');
  $self->{width}      = $self->{image}->get('text-width');

  $self->{image}->set(clip=>1);
  $self->{image}->set(clip_height=>$self->{height});
  $self->{image}->set(clip_width=>$self->{width});
}

# my $image = $content->content_get_image();

sub content_get_image
{
    my $self = shift(@_);

    my $image = Gnome2::Canvas::Item->new($self->{group}, 'Gnome2::Canvas::Text',
					  text=>$self->{text},
					  font_desc=>$self->{font_desc},
					  fill_color_gdk=>$self->{text_color_gdk}
					  );
    return $image;
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
sub content_set_width {
  my ($self, $value) = @_;
  $self->{image}->set('clip-width'=>$value);
}


# $self->content_set_height($value);

sub content_set_height
{
    my ($self, $value) = @_;

    $self->{image}->set('clip-height'=>$value);

    _layout_text($self);
}


# $self->content_set_param($param_name, $value);
sub content_set_param {
  my ($self, $param_name, $value) = @_;
  $self->{image}->set($param_name=>$value);
}


# $content->set(x=>0, y=>10, width=>20, height=>30);
sub set {
  my $self = shift(@_);
  my %attributes = @_;
  foreach my $param_name (keys %attributes) {
    my $value = $attributes{$param_name};
    if ($param_name eq 'text_color_gdk') {
      $self->{text_color_gdk} = $value;
      $self->{image}->set('fill-color-gdk'=>$value);
      next;
    }
    if ($param_name eq 'text') {
      $self->{text} = $value;
      $self->{image}->set(text=>$value);
      next;
    }
    $self->SUPER::set($param_name=>$value);
  }
}

1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Content::EllipsisText

Displays text on a Gnome2::Canvas. If there is too much text to fit in
the space allotted, the text will be truncated and an ellipsis will be
appended.

=head2 Methods

=over

=item C<new(group=E<gt>$group, text=E<gt>$text, ...)>

Instantiate a StreamGraph::View::Content::EllipsisText content
item. You must give a Gnome2::Canvas::Group on which to place the
content item, and you must give a text string that is to be displayed.

=item C<content_get_image()>

Returns a Gnome2::Canvas::Text item contains the text content.

=item C<content_set_x()>

Sets the x-coordinate of the Gnome2::Canvas::Text item, and adjusts
the layout of the text.

=item C<content_set_y()>

Sets the y-coordinate of the Gnome2::Canvas::Text item, and adjusts
the layout of the text.

=item C<content_set_width()>

Sets the width of the Gnome2::Canvas::Text item, and adjusts the
layout of the text.

=item C<content_set_height()>

Sets the height of the Gnome2::Canvas::Text item, and adjusts the
layout of the text.

=item C<content_set_param()>

Sets the value of a Gnome2::Canvas::Text property.

=item C<set(property=E<gt>$value>

Sets the color of the text, or assigns new text to the
Gnome2::Canvas::Text item.

=item C<update ()>

Sets height and width based on the text size.

=back
