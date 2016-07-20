package StreamGraph::Model::CodeObject::Parameter;

use warnings;
use strict;

use Moo;
extends "StreamGraph::Model::CodeObject";

use Data::Dump qw(dump);

has value	=> ( is=>"rw" );

sub BUILDARGS {
	my ($class, %args) = @_;
	
	my $node = delete $args{node};
	$node->{data}->{'_generated'} = 1;
	$args{outputType} = $node->{data}->outputType;
	$args{value} = $node->{data}->value;
	$args{name} = $node->{data}->name;
	return \%args;
}

1;