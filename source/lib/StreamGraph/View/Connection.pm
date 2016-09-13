package StreamGraph::View::Connection;

our $VERSION = '0.000001';

use warnings;
use strict;

use List::Util;

use Gnome2::Canvas;

use POSIX qw(DBL_MAX);

use Glib ':constants';
use Glib::Object::Subclass
	Gnome2::Canvas::Bpath::, properties => [
	Glib::ParamSpec->string(
		'arrows',                   'arrow-type',
		'Type of arrow to display', 'none',
		G_PARAM_READWRITE
	),

	Glib::ParamSpec->scalar(
		'predecessor_item',      'predecessor_item',
		'Predecessor view item', G_PARAM_READWRITE
	),

	Glib::ParamSpec->scalar(
		'item', 'item_item', 'Item view_item',
		G_PARAM_READWRITE
	),

	Glib::ParamSpec->scalar(
		'type', 'type', 'Connection type',
		G_PARAM_READWRITE
	),
	];

sub INIT_INSTANCE {
	my $self = shift(@_);
	$self->{x1} = 0;
	$self->{y1} = 0;
	$self->{x2} = 0;
	$self->{y2} = 0;
	$self->{predecessor_item} = undef;
	$self->{predecessor_signal_id} = 0;
	$self->{item} = undef;
	$self->{item_signal_id} = 0;
	$self->{type} = 'default';
	$self->{toggles} = {};
}

sub SET_PROPERTY {
	my ( $self, $pspec, $newval ) = @_;
	my $param_name = $pspec->get_name();
	if ($param_name eq 'predecessor_item') {
		if (( defined $self->{predecessor_item} )
			&& ( $self->{predecessor_item} != $newval )) {
				$self->{predecessor_item}
					->signal_handler_disconnect( $self->{predecessor_signal_id} );
		}

		$self->{predecessor_item} = $newval;
		$self->{predecessor_signal_id}
			= $newval->signal_connect( 'connection_adjust' =>
				sub { _predecessor_connection( $self, @_ ); } );
	}

	if ($param_name eq 'item') {
		if (( defined $self->{item} ) && ( $self->{item} != $newval )) {
			$self->{item}
				->signal_handler_disconnect( $self->{item_signal_id} );
		}
		$self->{item} = $newval;
		$self->{item_signal_id} = $newval->signal_connect(
			'connection_adjust' => sub { _item_connection( $self, @_ ); } );
	}

	if ($param_name eq 'type') {
		$self->{type} = $newval;
	}

	$self->{$param_name} = $newval;
	# print "Connection, SET_PROPERTY, name: $param_name  value: $newval\n";
	if ((defined $self->{predecessor_item}) && (defined $self->{item})) {
		_set_connection_path($self);
	}
}

sub connection_event {
  my ($self, $view, $event) = @_;

	if ($event->type eq 'enter-notify') {
		$self->set(width_pixels => 5);
		$view->{focusCon} = $self;
	} elsif ($event->type eq 'leave-notify') {
		$self->set(width_pixels => 1);
		undef $view->{focusCon};
	}
}

sub connect {
	my $self = shift(@_);
	$self->{predecessor_signal_id}
		= $self->{predecessor_item}->signal_connect(
		'connection_adjust' => sub { _predecessor_connection( $self, @_ ); }
		);
	$self->{item_signal_id} = $self->{item}->signal_connect(
		'connection_adjust' => sub { _item_connection( $self, @_ ); } );
}

sub disconnect {
	my $self = shift(@_);
	$self->{predecessor_item}
		->signal_handler_disconnect( $self->{predecessor_signal_id} );
    $self->{item}->signal_handler_disconnect( $self->{item_signal_id} ) if defined $self->{item};
	$self->{toggles}{top}->destroy if defined $self->{toggles}{top};
	$self->{toggles}{down}->destroy if defined $self->{toggles}{down};
}

sub update {
	shift->_set_connection_path();
}

sub _direction {
    return ('down', 'down');
}

sub _item_connection {
	my $self = shift(@_);
	my $direction = (
		_direction($self->get('predecessor_item'), $self->get('item'))
	)[1];

	my $side = ( $direction eq 'down' ) ? 'top' : 'down';
	my ( $x2, $y2 ) = $self->get('item')->get_connection_point($side,$self);
	my @successors = $self->get('item')->successors($side);
	my $offset
		= ( $side eq 'top' )
		? -3
		: 3;    # FIXME: UGH should be radius of toggle.
	$self->{x2} = ( scalar @successors > 0 ) ? $x2 + $offset : $x2;
	$self->{y2} = $y2;
	_set_connection_path($self);
}

sub _predecessor_connection {
	my $self = shift(@_);
	my $direction = (
		_direction($self->get('predecessor_item'), $self->get('item'))
	)[0];
	my ($x1, $y1) = $self->get('predecessor_item')->get_connection_point($direction,$self);
	my @successors = $self->get('predecessor_item')->successors($direction);
	my $offset
		= ( $direction eq 'top' )
		? -3
		: 3;    # FIXME: UGH should be radius of toggle.
	$self->{x1} = ( scalar @successors > 0 ) ? $x1 + $offset : $x1;
	$self->{y1} = $y1;
	_set_connection_path($self);
}

sub _bpath {
	my $self = shift(@_);
	my $x1 = $self->{x1};
	my $y1 = $self->{y1};
	my $x2 = $self->{x2};
	my $y2 = $self->{y2};
	$y2 -= 6; # offset by toggle height
	my ( $predecessor_direction, $item_direction )
		= _direction( $self->get('predecessor_item'), $self->get('item') );
	my $c = List::Util::max( 25, abs( ( ( $y2 - $y1 ) / 2 ) ) );
	my $a = $y1 + $c;
	my $b = $y2 - $c;
	my @p = ( $x1, $y1, $x1, $a, $x2, $b, $x2, $y2 );
	my $pathdef = Gnome2::Canvas::PathDef->new();
	$pathdef->moveto( $p[0], $p[1] );
	$pathdef->curveto( $p[2], $p[3], $p[4], $p[5], $p[6], $p[7] );
	return $pathdef if ($self->get('arrows') eq 'none' );
	my $h = 4 * $self->get('width-pixels');    # Height of arrow head.
	my $v = $h / 2;
	@p = ( $x2 - $v, $y2, $x2 + $v, $y2, $x2, $y2 + $h );

	$pathdef->lineto( $p[4], $p[5] );
	$pathdef->lineto( $p[0], $p[1] );
	$pathdef->lineto( $p[2], $p[3] );
	$pathdef->lineto( $p[4], $p[5] );

	if (defined $self->{toggles}{top}) {
		my $image = $self->{toggles}{top};
		$image->set(
			x1 => $self->{x1} - 3,
			y1 => $self->{y1} - 3,
			x2 => $self->{x1} + 3,
			y2 => $self->{y1} + 3,
		);
		$image->show;
	}
	if (defined $self->{toggles}{down}) {
		my $image = $self->{toggles}{down};
		$image->set(
			x1 => $self->{x2} - 3,
			y1 => $self->{y2} - 3,
			x2 => $self->{x2} + 3,
			y2 => $self->{y2} + 3,
		);
		$image->show;
	}
	return $pathdef;
}

sub _set_connection_path {
	my $self = shift(@_);
	$self->set_path_def( _bpath($self) );
	$self->show();
}

1;    # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Connection;

This module is internal to StreamGraph::View. Connections are
instantiated by StreamGraph::View.  This module is responsible for
drawing the connecting lines between StreamGraph::View::Items onto
the canvas.

The StreamGraph::View::Connection is an observer. It registers
with the view items so that it may be notified when a view item's
state changes.

=head2 Properties

=over

=item 'arrows' (string : readable / writable)

Indicates whether arrows should be drawn. Possible values are:
C<none>, C<one-way>, and C<two-way>.

=item 'predecessor_item' (StreamGraph::View::Item : readable / writable)

The item at which this connection starts.

=item 'item' (StreamGraph::View::Item : readable / writable)

The item at which this connection ends.

=back

=head2 Methods

=over

=item INIT_INSTANCE

This subroutine is called by Glib::Object::Subclass as the object is
being instantiated. You should not call this subroutine directly.
Leave it alone.

=item SET_PROPERTY

This subroutine is called by Glib::Object::Subclass when a property is
being set. You should not call this subroutine directly. Leave it
alone. Instead call the C<set> method to assign values to properties.

=item connect

Connect the StreamGraph::View::Connection to the items it
observes.


=item disconnect

Disconnect the StreamGraph::View::Connection from the items it
observes.

=back
