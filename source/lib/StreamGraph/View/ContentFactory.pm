package StreamGraph::View::ContentFactory;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;
use Glib ':constants';

use StreamGraph::View::Content::EllipsisText;
use StreamGraph::View::Content::Picture;
use StreamGraph::View::Content::Uri;
use StreamGraph::View::ArgUtils;


sub new {
	my $class = shift(@_);
	my @attributes = @_;
	my $self = {};
	bless $self, $class;
	my %attributes = @attributes;
	args_valid( \%attributes, qw(view font_desc text_color_gdk) );
	args_required( \%attributes, qw(view) );
	args_store( $self, \%attributes );
	if ( !( $self->{view}->isa('StreamGraph::View') ) ) {
		carp "Invalid StreamGraph::View argument.\n";
	}
	arg_default( $self, "font_desc", Gtk2::Pango::FontDescription->from_string("Ariel Normal 10") );
	arg_default( $self, "text_color_gdk", Gtk2::Gdk::Color->parse('black') );
	return $self;
}

sub create_content {
	my ( $self, @attributes ) = @_;
	my %attributes = @attributes;
	args_valid( \%attributes,
		qw(type text uri pixbuf browser font_desc text_color_gdk) );
	args_required( \%attributes, qw(type) );
	my $type = $attributes{type};
	my $text = $attributes{text};
	my $uri = $attributes{uri};
	my $browser = $attributes{browser};
	my $pixbuf = $attributes{pixbuf};
	my $font_desc
		= ( defined $attributes{font_desc} )
		? $attributes{font_desc}
		: $self->{font_desc};
	
	my $text_color_gdk
		= ( defined $attributes{text_color_gdk} )
		? $attributes{text_color_gdk}
		: $self->{text_color_gdk};
	
	if ( $type eq 'StreamGraph::View::Content::EllipsisText' ) {
		return StreamGraph::View::Content::EllipsisText->new(
			group          => $self->{view}->root,
			text           => $text,
			font_desc      => $font_desc,
			text_color_gdk => $text_color_gdk
		);
	}
	
	if ( $type eq 'StreamGraph::View::Content::Picture' ) {
		return StreamGraph::View::Content::Picture->new(
			group  => $self->{view}->root,
			pixbuf => $pixbuf
		);
	}
	
	if ( $type eq 'StreamGraph::View::Content::Uri' ) {
		return StreamGraph::View::Content::Uri->new(
			group          => $self->{view}->root,
			browser        => $browser,
			text           => $text,
			uri            => $uri,
			font_desc      => $font_desc,
			text_color_gdk => $text_color_gdk
		);
	}
	
	croak "Unexpected content type: $type\n";
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

StreamGraph::View::ContentFactory - Maker of standard content.


=head1 VERSION

This document describes StreamGraph::View::ContentFactory version
0.0.1


=head1 SYNOPSIS

use StreamGraph::View::ContentFactory;

=head1 DESCRIPTION

This module is internal to StreamGraph::View. This factory makes
content that can be passed to a StreamGraph::View::Border.

This module is called by StreamGraph::View::ItemFactory.

The following types of content may be created:

StreamGraph::View::Content::EllipsisText - Displays text with
optional ellipsis (...).

StreamGraph::View::Content::Picture - Displays a picture.

StreamGraph::View::Content::Uri - Displays a URI. User may click
on the URI.

=head1 INTERFACE 

=head2 Properties

=over

=item 'browser' (string)

A browser command. Is executed when a user clicks on a link. The
command contains a "%s" which is the insertion point for the url (see
below). When the user clicks on a StreamGraph::View::Content::Uri,
the browser command is built and executed.

=item 'font_desc' (Gtk2::Pango::FontDescription)

A Pango font description that styles text displayed to the user.

=item 'pixbuf' (Gtk2::Gdk::Pixbuf)

A pixbuf that is displayed to the user.

=item 'text' (string)

Text to be displayed.

=item 'text_color_gdk' (Gtk2::Gdk::Color)

The color of the text to be displayed.

=item 'type' (string)

The type of content to create (see above).

=item 'uri' (string)

Typically, an URL that may be clicked on to start up the browser
defined by the browser property (see above).

=item 'view' (StreamGraph::View)

The canvas on which content is drawn.

=back

=head2 Methods

=over

=item C<new (view=E<gt>$view)>

Constructor for this factory. Pass in a StreamGraph::View
argument.

=item C<create_content (type=>$content_type, ...)>

Returns a new StreamGraph::View::Content object.

=back

=head1 DIAGNOSTICS

=over

=item C<Invalid StreamGraph::View argument.>

You must pass in a StreamGraph::View argument.

=item C<Unexpected content type: $content_type>

The only content type that is supported are those that are predefined,
such as StreamGraph::View::Content::EllipsisText.

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
