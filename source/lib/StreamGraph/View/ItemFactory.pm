package StreamGraph::View::ItemFactory;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use StreamGraph::View::ContentFactory;
use StreamGraph::View::BorderFactory;
use StreamGraph::View::HotSpot::ToggleFactory;
use StreamGraph::View::HotSpot::GripFactory;
use StreamGraph::View::Item;
use StreamGraph::View::ArgUtils;
use StreamGraph::Model::Node;

use List::Util;
use Glib ':constants';

sub new {
	my $class = shift(@_);
	my @attributes = @_;
	my $self = {};
	bless $self, $class;

	my %attributes = @attributes;

	args_valid(\%attributes, qw(view font_desc fill_color_gdk text_color_gdk
				outline_color_gdk hotspot_color_gdk));
	args_required(\%attributes, qw(view));
	args_store($self, \%attributes);

	if (!($self->{view}->isa('StreamGraph::View'))) {
		carp "Invalid StreamGraph::View argument.\n";
	}

	arg_default($self, "font_desc",
		Gtk2::Pango::FontDescription->from_string("Ariel Normal 10"));
	arg_default($self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white'));
	arg_default($self, "text_color_gdk", Gtk2::Gdk::Color->parse('black'));
	arg_default($self, "outline_color_gdk", Gtk2::Gdk::Color->parse('gray'));
	arg_default($self, "hotspot_color_gdk", Gtk2::Gdk::Color->parse('orange'));

	$self->{content_factory} =
		StreamGraph::View::ContentFactory->new(view=>$self->{view});
	$self->{border_factory}  =
		StreamGraph::View::BorderFactory->new(view=>$self->{view});
	$self->{grip_factory}    = StreamGraph::View::HotSpot::GripFactory->new();
	$self->{toggle_factory}  = StreamGraph::View::HotSpot::ToggleFactory->new();

	return $self;
}


sub create_item {
	my ($self, @attributes) = @_;
	my %attributes = @attributes;

	args_valid(\%attributes, qw(border content text browser uri pixbuf
				font_desc fill_color_gdk text_color_gdk
				outline_color_gdk hotspot_color_gdk data));
	args_required(\%attributes, qw(border content));

	my $border_type       = $attributes{border};
	my $content_type      = $attributes{content};
	my $text              = $attributes{text};
	my $browser           = $attributes{browser};
	my $uri               = $attributes{uri};
	my $pixbuf            = $attributes{pixbuf};

	my $font_desc         = (defined $attributes{font_desc}) ?
						 $attributes{font_desc} : $self->{font_desc};
	my $fill_color_gdk    = (defined $attributes{fill_color_gdk}) ?
						 $attributes{fill_color_gdk} : $self->{fill_color_gdk};
	my $text_color_gdk    = (defined $attributes{text_color_gdk}) ?
						 $attributes{text_color_gdk} : $self->{text_color_gdk};
	my $outline_color_gdk = (defined $attributes{outline_color_gdk}) ?
						 $attributes{outline_color_gdk} : $self->{outline_color_gdk};
	my $hotspot_color_gdk = (defined $attributes{hotspot_color_gdk}) ?
						 $attributes{hotspot_color_gdk} : $self->{hotspot_color_gdk};

	my $content           = $self->{content_factory}->create_content(
							type=>$content_type, browser=>$browser,
							text=>$text, uri=>$uri, pixbuf=>$pixbuf,
							font_desc=>$font_desc,
							text_color_gdk=>$text_color_gdk);

	my $border            = $self->{border_factory}->create_border(
							type=>$border_type,
							content=>$content,
							fill_color_gdk=>$fill_color_gdk,
							outline_color_gdk=>$outline_color_gdk);

	my $item              = Gnome2::Canvas::Item->new(
							$self->{view}->root,
							'StreamGraph::View::Item',
							border=>$border,
							x=>(defined $attributes{data} ? $attributes{data}->x : 0),
							y=>(defined $attributes{data} ? $attributes{data}->y : 0));


	if (!defined($attributes{data}) or $attributes{data}->isa("StreamGraph::Model::Node::Filter")) {
		my $hotspot_in = $self->{toggle_factory}->create_toggle(
						item=>$item,
						border=>$border,
						side=>'left',
						fill_color_gdk=>$fill_color_gdk,
						outline_color_gdk=>$outline_color_gdk,
						hotspot_color_gdk=>$hotspot_color_gdk);
		$item->add_hotspot('toggle_left',  $hotspot_in);
		$content->{image}->{connect_item} = $item;
		$border->{border}->{connect_item} = $item;
		$hotspot_in->{image}->{connect_item} = $item;
	}
	if (!defined($attributes{data}) or !$attributes{data}->isa("StreamGraph::Model::Node::Comment")) {
		my $hotspot_out = $self->{toggle_factory}->create_toggle(
						item=>$item,
						border=>$border,
						side=>'right',
						fill_color_gdk=>$fill_color_gdk,
						outline_color_gdk=>$outline_color_gdk,
						hotspot_color_gdk=>$hotspot_color_gdk);
		$item->add_hotspot('toggle_right', $hotspot_out);
	}
	$item->set_data(defined $attributes{data} ?
		$attributes{data} :
		$item->set_data(StreamGraph::Model::NodeFactory->new
				->createNode(type=>"StreamGraph::Model::Node::Filter"))
	);

	return $item;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

StreamGraph::View::ItemFactory - Maker of standard view items.


=head1 VERSION

This document describes StreamGraph::View::ItemFactory version 0.0.1


=head1 SYNOPSIS

use StreamGraph::View::ItemFactory;

=head1 DESCRIPTION

This factory make StreamGraph::View::Items of various kinds. Four
"hotspots" are applied to each item that enable resizing of the
rectangle and expansion/collapse of the balanced graph.

The following border types are supported:

StreamGraph::View::Border::RoundedRect - Displays a rounded rectangle border.

StreamGraph::View::Border::Rectangle - Displays a rectangular border.

StreamGraph::View::Border::Ellipse - Displays an elliptical border.

The following content types are supported:

StreamGraph::View::Content::EllipsisText - Displays text with optional ellipsis (...)

StreamGraph::View::Content::Picture - Displays a picture in a pixbuf.

StreamGraph::View::Content::Uri - Displays a URI.


=head1 INTERFACE

=head2 Properties

=over

=item 'border' (string)

A string describing the type of border object to be instantiated. For
example, it might be: 'StreamGraph::View::Border::RoundedRect'.

=item 'browser' (string)

A string describing the command to execute with a given URI argument.

=item 'content' (string)

A string describing the type of content object to be instantiated. For
example, it might be: 'StreamGraph::View::Content::EllipsisText'.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color with which to fill the item.

=item 'font_desc' (Gtk2::Pango::FontDescription)

The font to use when showing the content.

=item 'hotspot_color_gdk' (Gtk2::Gdk::Color)

The color of a hotspot that is to be shown when the hotspot is engaged.

=item 'outline_color_gdk' (Gtk2::Gdk::Color)

The could with which to outline the item

=item 'pixbuf' (Gtk2::Gdk::Pixbuf)

An image to be displayed in a StreamGraph::View::Content::Picture.

=item 'text' (string)

The text to display in a StreamGraph::View::Content::EllipsisText or
StreamGraph::View::Content::Uri.

=item 'text_color_gdk' (Gtk2::Gdk::Color)

The color of the text to be displayed.

=item 'uri' (string)

The URI/URL to be referenced by the browser when the user clicks on a
link in the mind map.

=item 'view' (StreamGraph::View)

The canvas on which to draw mind map items.

=back

=head2 Methods

=over

=item C<new (view=E<gt>$view, ...)>

Constructor for this factory. Pass in a StreamGraph::View
argument, and optionally: C<font_desc>, C<fill_color_gdk>,
C<text_color_gdk>, C<outline_color_gdk>, C<hotspot_color_gdk>.

=item C<create_item (border=E<gt>$border_type, content=E<gt>$content_type, ...)>

Creates a new StreamGraph::View::Item with the specified border
and content, and optionally: C<font_desc>, C<fill_color_gdk>,
C<text_color_gdk>, C<outline_color_gdk>, C<hotspot_color_gdk>,
C<text>, C<browser>, C<uri>, C<pixbuf>.

=back

=head1 DIAGNOSTICS

=over

=item C<Invalid StreamGraph::View argument.>

You must pass in a StreamGraph::View argument as follows:
C<$factory = StreamGraph::View::ItemFactory-E<gt>new(view=E<gt>$view);>

=back


=head1 DEPENDENCIES

None.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-gtk2-ex-StreamGraphView@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

James Muir  C<< <hemlock@vtlink.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, James Muir C<< <hemlock@vtlink.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
