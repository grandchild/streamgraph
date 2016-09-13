package StreamGraph::View::HotSpot::ToggleFactory;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use StreamGraph::View::HotSpot::Toggle::Round;

use StreamGraph::View::ArgUtils;

use List::Util;

use Glib ':constants';

sub new {
    my $class = shift(@_);
    my @attributes = @_;
    my $self = {};
    bless $self, $class;
    my %attributes = @attributes;
    args_valid( \%attributes, qw(fill_color_gdk outline_color_gdk hotspot_color_gdk) );
    args_store( $self, \%attributes );
    arg_default( $self, "fill_color_gdk", Gtk2::Gdk::Color->parse('white') );
    arg_default( $self, "outline_color_gdk", Gtk2::Gdk::Color->parse('gray') );
    arg_default( $self, "hotspot_color_gdk", Gtk2::Gdk::Color->parse('orange') );
    return $self;
}

sub create_toggle {
    my ( $self, @attributes ) = @_;
    my %attributes = @attributes;
    args_valid( \%attributes, qw(item border side enabled fill_color_gdk outline_color_gdk hotspot_color_gdk) );
    args_required( \%attributes, qw(item border side) );
    my $item = $attributes{item};
    if ( !$item->isa('StreamGraph::View::Item') ) {
        croak "Invalid item. Item must be a 'StreamGraph::View::Item'.\n";
    }
    my $side = $attributes{side};
    if ( !grep { $_ eq $side } qw(down top) ) {
        croak "Invalid side. Must be 'down' or 'top'.\n";
    }
    my $border = $attributes{border};
    my $enabled = defined $attributes{enabled} ? $attributes{enabled} : TRUE;
    my $fill_color_gdk
        = ( defined $attributes{fill_color_gdk} )
        ? $attributes{fill_color_gdk}
        : $self->{fill_color_gdk};

    my $outline_color_gdk
        = ( defined $attributes{outline_color_gdk} )
        ? $attributes{outline_color_gdk}
        : $self->{outline_color_gdk};

    my $hotspot_color_gdk
        = ( defined $attributes{hotspot_color_gdk} )
        ? $attributes{hotspot_color_gdk}
        : $self->{hotspot_color_gdk};

    if ( $border->isa('StreamGraph::View::Border::Ellipse') ) {
        return StreamGraph::View::HotSpot::Toggle::Round->new(
            item              => $item,
            side              => $side,
            hotspot_color_gdk => $hotspot_color_gdk,
            outline_color_gdk => $outline_color_gdk,
            fill_color_gdk    => $fill_color_gdk,
            enabled           => $enabled
        );
    }

    if ( $border->isa('StreamGraph::View::Border::RoundedRect') ) {
        return StreamGraph::View::HotSpot::Toggle::Round->new(
            item              => $item,
            side              => $side,
            hotspot_color_gdk => $hotspot_color_gdk,
            outline_color_gdk => $outline_color_gdk,
            fill_color_gdk    => $fill_color_gdk,
            enabled           => $enabled
        );
    }

    if ( $border->isa('StreamGraph::View::Border::Rectangle') ) {
        return StreamGraph::View::HotSpot::Toggle::Round->new(
            item              => $item,
            side              => $side,
            hotspot_color_gdk => $hotspot_color_gdk,
            outline_color_gdk => $outline_color_gdk,
            fill_color_gdk    => $fill_color_gdk,
            enabled           => $enabled
        );
    }

    croak "Cannot make toggle. Unexpected border: $border\n";
}

1;    # Magic true value required at end of module
__END__

=head1 StreamGraph::View::HotSpot::ToggleFactory

This factory makes toggles that are used to expand or collapse the tree
of items shown in the mind map.

The following types of toggles are currently supported:

StreamGraph::View::HotSpot::Toggle::Round - The standard round
toggle.

This factory is used by the StreamGraph::View::ItemFactory.

=head2 Properties

=over

=item 'item' (StreamGraph::View::Item)

The item to attach the grip to.

=item 'border' (StreamGraph::View::Border)

The border that is used to determine the type of toggle to create.

=item 'side' (string)

The side of the item to attach to. May be: C<left> or C<right>.

=item 'fill_color_gdk' (Gtk2::Gdk::Color)

The color of the toggle.

=item 'outline_color_gdk' (Gtk2::Gdk::Color)

The color of the toggle outline.

=item 'hotspot_color_gdk' (Gtk2::Gdk::Color)

The color of the toggle when it is engaged.

=back

=head2 Methods

=over

=item C<new ( ...)>

Constructor for the toggle factory.

=item C<create_toggle (item=E<gt>$item, border=E<gt>$border, side=E<gt>$side, ...)>

Creates a new StreamGraph::View::HotSpot::Toggle given the
StreamGraph::View::Item that the toggle will attach to. The
StreamGraph::View::Border is used to determine what toggle to return
to the caller. The side may be C<top> or C<down>.

=back
