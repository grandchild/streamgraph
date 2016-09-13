package StreamGraph::View::BorderFactory;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use StreamGraph::View::Border::Ellipse;
use StreamGraph::View::Border::Rectangle;
use StreamGraph::View::Border::RoundedRect;

use StreamGraph::View::ArgUtils;

use List::Util;

use Glib ':constants';

sub new
{
    my $class = shift(@_);

    my @attributes = @_;

    my $self = {};

    bless $self, $class;

    my %attributes = @attributes;

    args_valid(\%attributes, qw(view fill_color_gdk outline_color_gdk));

    args_required(\%attributes, qw(view));

    args_store($self, \%attributes);

    if (!($self->{view}->isa('StreamGraph::View')))
    {
	carp "Invalid StreamGraph::View argument.\n";
    }

    arg_default($self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white'));

    arg_default($self, "outline_color_gdk", Gtk2::Gdk::Color->parse('gray'));

    return $self;
}


sub create_border
{
    my ($self, @attributes) = @_;

    my %attributes = @attributes;

    args_valid(\%attributes, qw(type content fill_color_gdk outline_color_gdk));

    args_required(\%attributes, qw(type content));

    my $content = $attributes{content};

    if (!$content->isa('StreamGraph::View::Content'))
    {
	croak "Invalid content. 'content' parameter must be a 'StreamGraph::View::Content'.\n";
    }

    my $type              = $attributes{type};

    my $fill_color_gdk    = (defined $attributes{fill_color_gdk}) ?
	                     $attributes{fill_color_gdk} : $self->{fill_color_gdk};

    my $outline_color_gdk = (defined $attributes{outline_color_gdk}) ?
	                     $attributes{outline_color_gdk} : $self->{outline_color_gdk};

    if ($type eq 'StreamGraph::View::Border::Ellipse')
    {
	return StreamGraph::View::Border::Ellipse->new(
		       group=>$self->{view}->root,
		       content=>$content,
		       fill_color_gdk=>$fill_color_gdk,
		       outline_color_gdk=>$outline_color_gdk);
    }

    if ($type eq 'StreamGraph::View::Border::RoundedRect')
    {
	return StreamGraph::View::Border::RoundedRect->new(
		       group=>$self->{view}->root,
		       content=>$content,
		       fill_color_gdk=>$fill_color_gdk,
		       outline_color_gdk=>$outline_color_gdk);
    }


    if ($type eq 'StreamGraph::View::Border::Rectangle')
    {
	return StreamGraph::View::Border::Rectangle->new(
		       group=>$self->{view}->root,
		       content=>$content,
		       fill_color_gdk=>$fill_color_gdk,
		       outline_color_gdk=>$outline_color_gdk);
    }

    croak "Unexpected border type: $type\n";
}


1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::BorderFactory

This factory makes borders for mind map view items. The following
types of borders are currently supported:

StreamGraph::View::Border::RoundedRect - A rounded rectangle
border.

StreamGraph::View::Border::Rectangle - A rectangular border.

StreamGraph::View::Border::Ellipse - An ellipse shaped border.

=head2 Properties

=over

=item 'view' (StreamGraph::View)

The canvas on which the border will be drawn.

=item 'type' (string)

The type of border to draw (see above).

=item 'content' (StreamGraph::View::Content)

The content to be placed in the border.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color of the interior of the border.

=item 'outline_color_gdk' (Gtk2::Gdk::Color)

The color of the border outline.

=back

=head2 Methods

=over

=item C<new (view=>$view, ...)>

Constructor for this factory. Pass in a StreamGraph::View
argument.

=item C<create_border (type=>$border_type, content=>$content, ...)>

Creates a new StreamGraph::View::Border border with the specified
content.

=back

=head1 DIAGNOSTICS

=over

=item C<Invalid StreamGraph::View argument.>

The 'view' parameter must be a StreamGraph::View.

=item C<Invalid content. 'content' parameter must be 'StreamGraph::View::Content')>

The only content types that subclass 'StreamGraph::View::Content' are permitted.

=item C<Unexpected border type: $type>

Only the border types listed above are currently supported.

=back
