package StreamGraph::View::Item;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;

use List::Util;
use Gnome2::Canvas;
use POSIX qw(DBL_MAX);
use Glib ':constants';
use Data::Dump qw(dump);

use Glib::Object::Subclass
	Gnome2::Canvas::Group::,

	signals => {
		'layout'            => { flags => 'run-last' },
		'connection_adjust' => { flags => 'run-last' },
		'hotspot_adjust'    => { flags => 'run-last' },
	},

	properties => [
		Glib::ParamSpec->scalar ('graph', 'graph',
					'The graph that this item belongs to', G_PARAM_READWRITE),
		Glib::ParamSpec->scalar ('column', 'column',
					'The column this item belongs to', G_PARAM_READWRITE),
		Glib::ParamSpec->scalar ('border', 'border',
					'The border and containing content', G_PARAM_READWRITE),
		Glib::ParamSpec->boolean ('visible', 'visible', 'Indicates whether the item is visible',
					 TRUE, G_PARAM_READWRITE),
		Glib::ParamSpec->double ('x', 'x', 'Upper left X coord',
					-(DBL_MAX), DBL_MAX, 0.0, G_PARAM_READWRITE),
		Glib::ParamSpec->double ('y', 'y', 'Upper left y coord',
					-(DBL_MAX), DBL_MAX, 0.0, G_PARAM_READWRITE),
		Glib::ParamSpec->double ('height', 'height', 'Height of map item',
					0.0, DBL_MAX, 25.0, G_PARAM_READWRITE),
		Glib::ParamSpec->double ('width', 'width', 'Width of map item',
					0.0, DBL_MAX, 300.0, G_PARAM_READWRITE),
		];


sub INIT_INSTANCE {
	my $self = shift(@_);
	$self->{graph}       = undef;
	$self->{column}      = undef;
	$self->{border}      = undef;
	$self->{hotspots}    = {};
	$self->{connections} = {};
	$self->{connections}{top} 		= ();
	$self->{connections}{down} 	= ();
	$self->{connections}{top_num} = 0;
	$self->{connections}{down_num} 	= 0;
	$self->{visible}     = TRUE;
	$self->{date_time}   = undef;
	$self->{data}        = undef;
}


sub SET_PROPERTY {
	my ($self, $pspec, $newval) = @_;
	my $param_name = $pspec->get_name;

#    print "Item, SET_PROPERTY: name: $param_name value: $newval\n";

	if ($param_name eq 'graph') {
		$self->{graph} = $newval;
		my @predecessors = $self->{graph}->predecessors($self);
		foreach my $predecessor_item (@predecessors) {
			$predecessor_item->signal_emit('hotspot_adjust');
		}
	}

	if ($param_name eq 'border') {
		if (!$newval->isa('StreamGraph::View::Border'))
		{
			print "Item, border: $newval\n";
			croak "Unexpected border. Must be 'StreamGraph::View::Border' type.\n";
		}
		$newval->reparent($self);
		my $content = $newval->get('content');
		croak ("Cannot set border, no content defined.\n") if (!defined $content);

		$content->reparent($self);
		if (defined $self->{border}) {
			my ($x, $y, $width, $height) = $self->{border}->get(qw(x y width height));
			$newval->set(x=>$x, y=>$y, width=>$width, height=>$height);
			$self->{border}->get('content')->destroy();
			$self->{border}->destroy();
		}

		$self->{border} = $newval;
		$self->set(width=>$newval->get('width'), height=>$newval->get('height'));
	}


	if ($param_name eq 'column') {
		if (!$newval->isa('StreamGraph::View::Layout::Column')) {
			croak "Unexpected column value.\nYou may only assign a " .
			  "'StreamGraph::View::Layout::Column as a column.\n";
		}

		$self->{column} = $newval;
	}

	if ($param_name eq 'visible') {
		$self->{visible} = $newval;
		if ($newval) {
			$self->show();
		} else {
			$self->hide();
		}
		$self->signal_emit('connection_adjust');
	}

	if ($param_name eq 'x') {
		$self->{x} = $newval;
		if (defined $self->{border}) {
			$self->{border}->set(x=>$newval);
			$self->signal_emit('hotspot_adjust');
			$self->signal_emit('connection_adjust');
		}
		if (defined $self->{data}) {
			$self->{data}->x($newval);
		}
		return;
	}


	if ($param_name eq 'y') {
		$self->{y} = $newval;
		if (defined $self->{border}) {
			$self->{border}->set(y=>$newval);
			$self->signal_emit('hotspot_adjust');
			$self->signal_emit('connection_adjust');
		}
		if (defined $self->{data}) {
			$self->{data}->y($newval);
		}
		return;
	}

	if ($param_name eq 'height') {
		$self->{height} = $newval;
		if (defined $self->{border}) {
			$self->{border}->set(height=>$newval);
			$self->signal_emit('hotspot_adjust');
			$self->signal_emit('connection_adjust');
		}
		return;
	}

	if ($param_name eq 'width') {
		$self->{width} = $newval;
		if (defined $self->{border}) {
			$self->{border}->set(width=>$newval);
			$self->signal_emit('hotspot_adjust');
			$self->signal_emit('connection_adjust');
		}
		return;
	}
}

sub update {
	my ($self) = @_;

	$self->{border}->update();
	$self->set(width=>$self->{border}->get('width'), height=>$self->{border}->get('height'));
	if ($self->isDataNode) {
		$self->{hotspots}{'toggle_left'}->set(enabled=>$self->{data}->inputType ne "void");
		$self->{hotspots}{'toggle_right'}->set(enabled=>$self->{data}->outputType ne "void");
	}
}

# $item->add_hotspot
sub add_hotspot {
	my ($self, $hotspot_type, $hotspot) = @_;
	$self->{hotspots}{$hotspot_type} = $hotspot;
}

# $item->add_connection($self, $side, $connection)
sub add_connection {
	my ($self, $side, $connection) = @_;
	unshift (@{$self->{connections}{$side}},$connection);
	if ($connection->{predecessor_item}->isDataNode) {$self->{connections}{$side . "_num"}++;}
	$self->signal_emit('hotspot_adjust');
	$self->signal_emit('connection_adjust');
}

# $item->add_connection($self, $side, $connection)
sub remove_connection {
	my ($self, $side, $connection) = @_;
	my $n = 0;
	for my $con (@{$self->{connections}{$side}}){
		if ($con eq $connection) {
			splice @{$self->{connections}{$side}}, $n, 1;
			if ($con->{predecessor_item}->isDataNode) {$self->{connections}{$side . "_num"}--;}
			last;
		}
		$n++;
	}
	$self->signal_emit('hotspot_adjust');
	$self->signal_emit('connection_adjust');
}

# $item->set_data($data);
sub set_data {
	my ($self, $data) = @_;
	if (!$data->isa('StreamGraph::Model::Node')) {
		print "Item, data: $data\n";
		croak "Unexpected data. Must be 'StreamGraph::Model::Node' type.\n";
	}
	$self->{data} = $data;
}

# $item->set_view($view);
sub set_view {
	my ($self, $view) = @_;
	$self->{view} = $view;
}

# $item->get_column_no();
sub get_column_no {
	my $self = shift(@_);
	my $column = $self->{column};
	if (!defined $column) {
		croak "Attempt to get column_no on undefined column.\n";
	}
	return $column->get('column_no');
}

sub select {
	my ($self,$switch) = @_;
	$self->{border}->select($switch);
}

# $item->get_connection_point('top');
sub get_connection_point {
	my ($self, $side, $connection) = @_;
	my $offset = $side eq 'top' ? 2 : 1;
	if (!$self->isDataNode) { return $self->{border}->get_connection_point($side,1,3); }
	if (!defined $connection) {
			return $self->{border}->get_connection_point($side,$offset-1,$self->{connections}{$side . "_num"}+$offset);
	}
	if (!$connection->{predecessor_item}->isDataNode) {
		return $self->{border}->get_connection_point($side,0,$self->{connections}{$side . "_num"}+$offset);
	}
	my $arr = $self->{connections}{$side};
	my $n = $offset;
	for my $con (@{$arr}) {
		if ($con eq $connection) {
			return $self->{border}->get_connection_point($side,$n,$self->{connections}{$side . "_num"}+$offset);
		}
		if ($con->{predecessor_item}->isDataNode) { $n++; }
	}
	return $self->{border}->get_connection_point($side,$offset-1,$self->{connections}{$side . "_num"}+$offset);
}


# my ($top, $left, $down, $right) = $item->get_insets();
sub get_insets {
	my $self = shift(@_);
	return $self->{border}->border_insets();
}


# my $min_height = $item->get_min_height();
sub get_min_height {
	my $self = shift(@_);
	return 0 if (!defined $self->{border});
	return $self->{border}->get_min_height();
}


# my $min_width = $item->get_min_width();
sub get_min_width {
	my $self = shift(@_);
	return 0 if (!defined $self->{border});
	return $self->{border}->get_min_width();
}


# $item->get_weight();
sub get_weight {
	my $self = shift(@_);
	return ($self->get('height') * $self->get('width'));
}

sub get_edge_data_to {
	my ($self, $target) = @_;
	return $self->{graph}->get_edge_attribute($self, $target, 'data');
}

sub get_edge_data_from {
	my ($self, $source) = @_;
	return $self->{graph}->get_edge_attribute($source, $self, 'data');
}

sub set_edge_attribute_to {
	my ($self, $target, $key, $value) = @_;
	$self->{graph}->set_edge_attribute($self, $target, $key, $value);
}

sub set_edge_attribute_from {
	my ($self, $source, $key, $value) = @_;
	$self->{graph}->set_edge_attribute($source, $self, $key, $value);
}

sub set_edge_data_to {
	my ($self, $target, $inMult, $outMult) = @_;
	if(undef($self) || undef($target) || undef($inMult)){
		print("either self or target are undefined or not enough parameters given");
		return;
	}
	my $previous = $self->get_edge_data_to($target);
	if(undef($previous)){
		$previous = StreamGraph::Model::ConnectionData->new();
		$self->set_edge_attribute_to($target, 'data', $previous);
	}
	$previous->inputMult($inMult);
	if(!undef($outMult)){
		$previous->outputMult($outMult);
	}
}

sub set_edge_data_from {
	my ($self, $source, $inMult, $outMult) = @_;
	if(undef($self) || undef($source) || undef($inMult)){
		print("either self or source are undefined or not enough parameters given");
		return;
	}
	my $previous = $self->get_edge_data_from($source);
	if(undef($previous)){
		$previous = StreamGraph::Model::ConnectionData->new();
		$self->set_edge_attribute_from($source, 'data', $previous);
	}
	$previous->inputMult($inMult);
	if(!undef($outMult)){
		$previous->outputMult($outMult);
	}
}


# $item->is_visible();
sub is_visible {
	my $self = shift(@_);
	return $self->get('visible');
}

# returns list of parameters as ...::CodeObject::Parameter unless parameterTypeFlag is set to 0
sub get_parameters {
	my $self = shift;
	if(!$self->{data}->isa("StreamGraph::Model::Node::Filter")){
		return ();
	}
	my $parameterTypeFlag = shift;
	if(!defined($parameterTypeFlag) || $parameterTypeFlag != 0){
		$parameterTypeFlag = 1;
	}
	my @ps = $self->predecessors("StreamGraph::Model::Node::Parameter");
	if($parameterTypeFlag == 1){
		my @parameters = ();
		foreach my $p (@ps) {
			if(!$p->{data}->{'_generated'}){
				my $newParameter = StreamGraph::Model::CodeObject::Parameter->new(node=>$p);
				$p->{data}->{'_codeObject'} = $newParameter;
				push(@parameters, $newParameter);
			} else {
				# update values
				$p->{data}->{'_codeObject'}->updateValues();
				push(@parameters, $p->{data}->{'_codeObject'});
			}
		}
		return \@parameters;
	} else {
		return \@ps;
	}
}

sub connections {
	my ($self, $direction) = @_;
	if ($direction eq "up") {
		return $self->predecessors;
	} else {
		return $self->successors;
	}
}

# my @predecessors = $item->predecessors();
sub predecessors {
	my ($self, $type) = @_;
	return () if (!defined $self->{graph});
	if (defined $type) {
		return grep { $_->{data}->isa($type) } $self->{graph}->predecessors($self);
	} else {
		return $self->{graph}->predecessors($self);
	}
}


# my @successors = $item->successors();
# my @successors = $item->successors('top');
sub successors {
	my ($self, $side) = @_;
	return () if (!defined $self->{graph});

	my @items = $self->{graph}->successors($self);
	return () if (scalar @items == 0);

	return @items if (!defined $side);

	my $column = $self->get('column');
	return () if (!defined $column);

	my $column_no = $column->get('column_no');
	if ($side eq 'down') {
		return grep {$_->get_column_no() >= $column_no } @items;
	}

	# $side eq 'top'
	return grep {$_->get_column_no() <= $column_no } @items;
}

# my @all_successors = $item->all_successors();
sub all_successors {
	my ($self, $side) = @_;
	return () if (!defined $self->{graph});

	my @items = $self->{graph}->all_successors($self);
	return () if (scalar @items == 0);

	return @items;
}

sub all_predecessors {
	my ($self) = @_;
	return () if (!defined $self->{graph});
	my @items = $self->{graph}->all_predecessors($self);
	return @items;
}

sub is_split {
	my $self = shift;
	#print($self->{data}->name . " asking for successors with a " . ref($self->{graph}) . "\n");
	return $self->successors > 1;
}

sub is_join {
	my $self = shift;
	return $self->predecessors("StreamGraph::Model::Node::Filter") > 1;
}

sub isFilter { return shift->{data}->isa("StreamGraph::Model::Node::Filter"); }
sub isSubgraph { return shift->{data}->isa("StreamGraph::Model::Node::Subgraph"); }
sub isDataNode { return shift->{data}->isDataNode; }
sub isParameter { return shift->{data}->isa("StreamGraph::Model::Node::Parameter"); }
sub isComment { return shift->{data}->isa("StreamGraph::Model::Node::Comment"); }

# resize: adjust the size of this item. This routine is needed because
# the simple: $self->set(x=>$x1, width=>$width, height=>$height) is
# too slow due to an excessive number of signals.
sub resize {
	my ($self, $side, $delta_x, $delta_y) = @_;
	$delta_x = $delta_x - $self->{width};
	$delta_y =  $delta_y - $self->{height};
	return if (!defined $self->{border});
	$self->raise(1);
	my ($x, $width, $height) = _resize($self, $side, $delta_x, $delta_y);
	$self->{x} = $x;
	$self->{width} = $width;
	$self->{height} = $height;
	$self->{border}->set(x=>$x, width=>$width, height=>$height);
	$self->signal_emit('hotspot_adjust');
	$self->signal_emit('connection_adjust');
}


sub _resize {
	my ($self, $side, $delta_x, $delta_y) = @_;
	my $min_height = $self->{border}->get_min_height();
	my $min_width = $self->{border}->get_min_width();
	my ($x, $width, $height) = $self->get(qw(x width height));
	if ($side eq 'down') {
		my $new_width = List::Util::max($min_width, ($width + $delta_x));
		my $new_height = List::Util::max($min_height, ($height + $delta_y));
		return ($x, $new_width, $new_height);
	}

	# $side eq 'top'
	my $new_width = List::Util::max($min_width, ($width - $delta_x));
	my $new_height = List::Util::max($min_height, ($height + $delta_y));
	my $new_x = ($new_width > $min_width) ? $x + $delta_x : $x;
	return ($new_x, $new_width, $new_height);
}


sub toggle_available {
	my ($self, $available) = @_;
	# foreach my $hotspot ($self->{hotspots}{'toggle_left'}) {
	if ($self->{hotspots}{toggle_left}) {
		$self->{hotspots}{toggle_left}->hotspot_toggle_available($self, $available ? 1 : 0);
		$self->signal_emit('hotspot_adjust');
	}
}


sub _set_visible {
	my ($self, $date_time) = @_;
#    print "_set_visible, self: $self  date_time: $date_time  self date time: $self->{hide_date_time}\n";
	if ((!defined $self->{hide_date_time}) || ($self->{hide_date_time} == $date_time)) {
		$self->set(visible=>TRUE);
		$self->{hide_date_time} = undef;
	}
}


sub _set_invisible {
	my ($self, $date_time) = @_;
#    print "_set_invisible, self: $self  date_time: $date_time\n";
	if ($self->is_visible()) {
		$self->set(visible=>FALSE);
		$self->{hide_date_time} = $date_time;
	}
}

1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Item

StreamGraph::View::Item items contain the border and content that
is displayed in the mind map. They may be created using
StreamGraph::View::ItemFactory and may be placed into
StreamGraph::View.

=head2 Properties

=over

=item C<graph> (StreamGraph::View::Graph)

A reference to the StreamGraph::View::Graph that contains all the
StreamGraph::View::Item items.

=item C<border> (StreamGraph::View::Border)

A reference to the StreamGraph::View::Border that is drawn on the
canvas. The border contains a reference to the content.

=item C<visible> (boolean)

A flag indicating whether or not this item is visible.

=item C<x> (double)

The upper left x-coordinate of the item.

=item C<y> (double)

The upper left y-coordinate of the item.

=item C<height> (double)

The height of the item.

=item C<width> (double)

The width of the item.

=back

=head2 Methods

=over

=item C<INIT_INSTANCE>

This subroutine is called by Glib::Object::Subclass whenever a
StreamGraph::View::Item is instantiated. It initialized the
internal variables used by this object. This subroutine should not be
called by you. Leave it alone.

=item C<SET_PROPERTY>

This subroutine is called by Glib::Object::Subclass whenever a
property value is being set.  Property values may be set using the
C<set()> method. For example, to set the width of an item to 100
pixels you would call set as follows:
C<$item-E<gt>set(width=E<gt>100);>

=item C<add_hotspot ($hotspot_type, $hotspot)>

Add a StreamGraph::View::ItemHotSpot to an item. There are two
types of hotspots ('toggle_top','toggle_down').

The "toggle" hotspots correspond to the small circles you see on a
view item that allow for connecting two items.

You should add a hotspot for each hotspot type to an item. If you use
the StreamGraph::View::ItemFactory to create items, this will be
done for you.

When you add a hotspot the hotspot type is used to position the
hotspot on the item. You may only add one hotspot of each type.

=item C<disable_hotspots ()>

This method is used to disable and hide the "toggle" hotspots, which
only appear on an item if they are needed.

=item C<enable_hotspots ($successor_item)>

This method enables and shows the "toggle" hotspots provided that they
are needed by the item. In item needs a toggle hotspot if it has
successor items attached to it.

=item C<get_column_no>

Return the column number that this item belongs to. The column number
is used to determine the relative position of items in the layout.

=item C<get_connection_point ($side,$connection)>

Return the x,y coordinates of the point at which a
StreamGraph::View::Connection may connect to. This coordinate is
also used to detemine where to place the "toggle" hotspots.

=item C<get_insets ()>

Return the C<($top, $left, $down, $right)> border insets. The insets
are used by the Grips and Toggles to position themselves.

=item C<get_min_height()>

Return the minimum height of this item.

=item C<get_min_width()>

Return the minimum width of this item.

=item C<get_weight ()>

Return the "weight" of a view item. The weight is the product of the
item height and width. The weight is used by
StreamGraph::View::Layout::Balanced to determine the side of the
mind map on which to place the item.

=item C<is_visible ()>

Return true if this item is visible.

=item C<predecessors ()>

Return an array of predecessor items of this item.

=item C<resize ()>

Adjust the height and width of the item, and then signal to the
toggles, grips and connections to redraw themselves.

=item C<successors ()>

Return an array of successor items of this item.

=item C<successors ($side)>

Return an array of items that are on one side of this item. The side
may be 'top' or 'down'.

=item C<update ()>

Sets height and width based on the content size.

=item C<add_connection($self, $side, $connection)>

This method adds a connection to the list of top or down connections.
Evry items has complete list of all top or down connections.

=item C<remove_connection($self, $side, $connection)>

This method removes a connection from the list of top or down connections.

=item C<set_data($data)>

This method sets the data node.

=item C<set_view($view)>

This method sets the $view. This is necessary, because items can access view functions.

=item C<select($switch)>

This method changes the background color of the item based on the switch value
(0 -> white or 1 -> blue).

=item C<get_edge_data_to($target)>

C<return> StreamGraph::Model::ConnectionData

Get the data attribute of the connection to the C<$target>


=item C<get_edge_data_from($source)>

C<return> StreamGraph::Model::ConnectionData

Get the data attribute of the connection from the C<$source>


=item C<set_edge_attribute_to($target, $key, $value)>

Set the generic attribute with C<$key> and C<$value> for the edge to the C<$target>.


=item C<set_edge_attribute_from($source, $key, $value)>

Set the generic attribute with C<$key> and C<$value> for the edge from the C<$source>.


=item C<set_edge_data_to($target, $graph, $inMult, $outMult)>

Set the data for the edge to the C<$target>. Requires input and output
multiplicities for the connection.


=item C<set_edge_data_from($source, $graph, $inMult, $outMult)>

Set the data for the edge from the C<$source>. Requires input and output
multiplicities for the connection.


=item C<get_parameters()>

C<return> list[StreamGraphModel::Node::Parameter] or list[StreamGraph::Model::CodeObject::Parameter] as specified.

If the C<$parameterTypeFlag> is not given or true a 
list[StreamGraphModel::CodeObject::Parameter] is returned. 
Otherwise a list[StreamGraphModel::Node::Parameter] is returned. The 
returned list has all parameters that are connected to the filter in the 
C<$graph>. 


=item C<connections($direction)>

C<return> list[StreamGraph::View::Item]

Returns predecessors if C<$direction> equals "up", successors otherwise.


=item C<all_successors()>

C<return> list[StreamGraph::View::Item]

returns successors and all their successors.


=item C<all_predecessors()>

C<return> list[StreamGraph::View::Item]

returns predecessors and all their predecessors.


=item C<is_split()>

C<return> Boolean

Checks if item has more than one predecessor that is not a parameter.


=item C<is_join()>

C<return> Boolean

Checks if the item has more than one successor.


=item C<isFilter()>

C<return> Boolean

Checks if the items data field is of the StreamGraph::Model::Node::Filter class.


=item C<isSubgraph()>

C<return> Boolean

Checks if the items data field is of the StreamGraph::Model::Node::Subgraph class.


=item C<isDataNode()>

C<return> Boolean

Checks if the items data field is either of the StreamGraph::Model::Node::Filter 
class or of the StreamGraph::Model::Node::Subgraph class.


=item C<isParameter()>

C<return> Boolean

Checks if the items data field is of the StreamGraph::Model::Node::Parameter class.


=item C<isComment()>

C<return> Boolean

Checks if the items data field is of the StreamGraph::Model::Node::Comment class.

=back
