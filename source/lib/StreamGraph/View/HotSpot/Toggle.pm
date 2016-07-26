package StreamGraph::View::HotSpot::Toggle;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use Glib ':constants';
use Gnome2::Canvas;
use StreamGraph::View::Connection;
use base 'StreamGraph::View::HotSpot';


# $self->hotspot_adjust_event_handler($item);

sub hotspot_adjust_event_handler {
		my ($self, $item) = @_;
}

sub hotspot_motion_notify {
	my ($self, $item, $event) = @_;
	if (defined $item->{view}->{toggleCon}) {
		my @coords = $event->coords;
		my $found = $item->{view}->get_item_at($coords[0], $coords[1]);
		if (defined $found->{connect_item} && $item->{view}->{graph}->is_connectable($item,$found->{connect_item})) {
			@coords = $found->{connect_item}->get_connection_point("top");
		} else {
			$coords[0] -= 5;
			$coords[1] -= 5;
		}
		$item->{view}->{toggleCon}->{x2} = shift @coords;
		$item->{view}->{toggleCon}->{y2} = shift @coords;
		$item->{view}->{toggleCon}->_predecessor_connection();
	}
}

sub hotspot_enter_notify {
	my ($self, $item, $event) = @_;
}

# $self->hotspot_button_release($item, $event);
sub hotspot_button_release {
	my ($self, $item, $event) = @_;
	if ($self->{side} eq 'top' || !defined $item->{view}->{toggleCon}) { return; }
	my @coords = $event->coords;
	$self->end_connection;
	my $found = $item->{view}->get_item_at($coords[0], $coords[1]);
	if (defined $found->{connect_item}) {
		$item->{view}->connect($item, $found->{connect_item}) if $item ne $found->{connect_item};
	}
}

sub end_connection {
	my ($self) = @_;
	my $item = $self->{item};
	my @items = $item->{graph}->get_items;
	foreach my $i (@items) {
		$i->toggle_available(0);
	};
	$item->{view}->{toggleCon}->disconnect();
	$item->{view}->{toggleCon}->destroy();
	undef $item->{view}->{toggleCon};
}

sub hotspot_button_press {
	my ($self, $item, $event) = @_;
	if ($self->{side} eq 'top') { return; }
	my @items = $item->{graph}->all_non_predecessors($item);
	foreach my $i (@items) {
		$i->toggle_available(1) if $item->{view}->{graph}->is_connectable($item,$i);
	};
	$item->{view}->{toggleCon} = Gnome2::Canvas::Item->new(
		$item->{view}->root,
		'StreamGraph::View::Connection',
		predecessor_item=>$item,
		arrows=>$item->{view}->{connection_arrows},
		width_pixels=>1,
		outline_color_gdk=>$item->{view}->{connection_colors_gdk}{default},
		fill_color=>'darkblue'
	);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

StreamGraph::View::HotSpot::Toggle - Manage a toggle type "hot
spot" on a view item.


=head1 VERSION

This document describes StreamGraph::View::HotSpot::Toggle version 0.0.1

=head1 HEIRARCHY

=head1 SYNOPSIS

use base 'StreamGraph::View::HotSpot::Toggle';


=head1 DESCRIPTION

The StreamGraph::View::HotSpot::Toggle defines toggle type
hotspots. This kind of hot spot is used to expand and collapse
StreamGraph::View::Items.

=head1 INTERFACE

=head2 Properties

=over

No properties defined.

=back

=head2 Methods

=over

=item C<new (item=E<gt>$item)>

Instantiates a toggle type hotspot.

=item C<hotspot_adjust_event_handler>

Overrides method defined in StreamGraph::View::HotSpot. This
method sets the proper state of the toggle when a "hotspot_adjust"
event occurs.


=item C<hotspot_button_release>

Overrides method defined in StreamGraph::View::HotSpot. This
method actually toggles items in the mind map view.

=back

=head1 DIAGNOSTICS

=over

No Diagnostics

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
