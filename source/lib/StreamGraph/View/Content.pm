package StreamGraph::View::Content;

our $VERSION = '0.000001';

use warnings;
use strict;
use Carp;
use List::Util;

use Gnome2::Canvas;
use constant MIN_WIDTH  => 10;
use constant MIN_HEIGHT => 10;

use StreamGraph::View::ArgUtils;


sub new {
	my $class = shift(@_);
	my $self = {};
	bless $self, $class;
	my %attributes = @_;
	args_required( \%attributes, 'group' );
	args_store( $self, \%attributes );
	arg_default( $self, "x", 0 );
	arg_default( $self, "y", 0 );
	arg_default( $self, "height", MIN_HEIGHT );
	arg_default( $self, "width", MIN_WIDTH );
	arg_default( $self, "min_width", MIN_WIDTH );
	arg_default( $self, "min_height", MIN_HEIGHT );
	return $self;
}

# my $image = $content->content_get_image();
sub content_get_image {
	my $self = shift(@_);
	croak "You must supply a content image by overriding 'content_get_image'.\n";
}

# $self->content_set_x($value);
sub content_set_x {
	my ( $self, $value ) = @_;
	croak "You must set the content x coordinate by overriding 'content_set_x'.\n";
}

# $self->content_set_y($value);
sub content_set_y {
	my ( $self, $value ) = @_;
	croak "You must set the content y coordinate by overriding 'content_set_y'.\n";
}

# $self->content_set_width($value);
sub content_set_width {
	my ( $self, $value ) = @_;
	croak "You must set the content width by overriding 'content_set_width'.\n";
}

# $self->content_set_height($value);
sub content_set_height {
	my ( $self, $value ) = @_;
	croak "You must set the content height by overriding 'content_set_height'.\n";
}

# $self->content_set_param($param_name, $value);
sub content_set_param {
	my ( $self, $param_name, $value ) = @_;
}

# my @values = $content->get(qw(x y width height));
sub get {
	my $self = shift(@_);
	return undef if ( scalar @_ == 0 );
	return _get( $self, shift(@_) ) if ( scalar @_ == 1 );
	my @values = ();
	foreach my $param_name (@_) { push @values, _get( $self, $param_name ); }
	return @values;
}

# $canvas->reparent($group);
sub reparent {
	my ( $self, $group ) = @_;
	$self->{group} = $group;
	#FIXME: shouldn't reference image here...??
	$self->{image}->reparent($group);
}

# $content->set(x=>0, y=>10, width=>20, height=>30);
sub set {
	my $self = shift(@_);
	my %attributes = @_;
	foreach my $param_name ( keys %attributes ) {
		my $value = $attributes{$param_name};
		if ( $param_name eq 'x' ) {
			next if ( $self->{x} == $value );
			$self->{x} = $value;
			$self->content_set_x($value);
			next;
		}
		if ( $param_name eq 'y' ) {
			next if ( $self->{y} == $value );
			$self->{y} = $value;
			$self->content_set_y($value);
			next;
		}
		if ( $param_name eq 'height' ) {
			next if ( $self->{height} == $value );
			$self->{height} = $value;
			$self->content_set_height($value);
			next;
		}
		if ( $param_name eq 'width' ) {
			next if ( $self->{width} == $value );
			$self->{width} = $value;
			$self->content_set_width($value);
			next;
		}
		$self->content_set_param( $param_name, $value );
	}
}

sub get_min_height {
	my $self = shift(@_);
	return $self->{min_height};
}

sub get_min_width {
	my $self = shift(@_);
	return $self->{min_width};
}

sub _get {
	my ( $self, $param_name ) = @_;
	my $value = $self->{$param_name};
	croak "Undefined value for key $param_name.\n" if ( !defined $value );
	return $value;
}

1;    # Magic true value required at end of module
__END__

=head1 StreamGraph::View::Content

This module is internal to StreamGraph::View. It is the base class
for objects that show content and offers several classes that are to
be overidden.

=head2 Properties

=over

=item 'group' (Gnome2::Canvas::Group)

The group on which the content is drawn.

=item 'x' (double)

The x-coordinate of the upper left corner of the content bounding box.

=item 'y' (double)

The y-coordinate of the upper left corner of the content bounding box.

=item 'width' (double)

The width of the content bounding box.

=item 'height' (double)

The height of the content bounding box.

=item 'min_width' (double)

The minimum width of the content.

=item 'min_height' (double)

The minimum height of the content.

=back

=head2 Methods

=over

=item C<new(group=E<gt>$group, ...)>

Instantiate a content object. You must provide the
Gnome2::Canvas::Group on which this content is to place itself.

=item C<content_get_image()>

This method must be overridden. It is used to instantiate
Gnome2::Canvas::Item content.

=item C<content_set_x($value)>

This method must be overridden. It sets the value of the content x
coordinate.

=item C<content_set_y($value)>

This method must be overridden. It sets the value of the content y
coordinate.

=item C<content_set_width($value)>

This method must be overridden. It sets the value of the content width.

=item C<content_set_height($value)>

This method must be overridden. It sets the value of the content
height.

=item C<content_set_param($name, $value)>

This method may optionally be overridden to pass values to the object
created by content_get_image.

=item C<get('name')>

Return the value of a property.

=item C<set(name=E<gt>$value>

This method is used to set the value of a property.

=item C<get_min_height>

Returns the minimum height for a StreamGraph::View::Content

=item C<get_min_width>

Returns the minimum width for a StreamGraph::View::Content

=item C<reparent($group)>

Assign this content item to another Gnome2::Canvas::Group.

=back
