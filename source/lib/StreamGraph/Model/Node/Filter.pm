package StreamGraph::Model::Node::Filter;

use warnings;
use strict;
use StreamGraph::Model::CodeObject::Parameter;

use Moo;
extends "StreamGraph::Model::Node";

has initCode            => ( is=>"rw", default=>"" );
has workCode            => ( is=>"rw", default=>"" );
has globalVariables     => ( is=>"rw", default=>"" );
has timesPush           => ( is=>"rw", default=>0 );
has timesPop            => ( is=>"rw", default=>0 );
has timesPeek           => ( is=>"rw", default=>0 );

has joinType            => ( is=>"rw", default=>"roundrobin" );
has joinMultiplicities  => ( is=>"rw", default=>(0) );

has splitType           => ( is=>"rw", default=>"duplicate" );
has splitMultiplicities => ( is=>"rw", default=>(0) );

has inputType           => ( is=>"rw", default=>"void" );
has inputCount          => ( is=>"rw", default=>0 );

has outputType          => ( is=>"rw", default=>"void" );
has outputCount         => ( is=>"rw", default=>0 );

has saveMembers         => ( is=>"ro", default=>sub{[qw(
	name
	id
	x
	y
	initCode
	workCode
	globalVariables
	timesPush
	timesPop
	timesPeek
	joinType
	joinMultiplicities
	splitType
	splitMultiplicities
	inputType
	inputCount
	outputType
	outputCount
)]});

sub get_parameters {
	my $self = shift;
	my $graph = shift;
	if(!$self->isa("StreamGraph::Model::Node::Filter")){
		return ();
	}
	my $parameterTypeFlag = shift;
	if(!defined($parameterTypeFlag) || $parameterTypeFlag != 0){
		$parameterTypeFlag = 1;
	}
	my @ps = $graph->predecessors($self, "StreamGraph::Model::Node::Parameter");
	if($parameterTypeFlag == 1){
		my @parameters = ();
		foreach my $p (@ps) {
			if(!$p->{'_generated'}){
				my $newParameter = StreamGraph::Model::CodeObject::Parameter->new(node=>$p);
				$p->{'_codeObject'} = $newParameter;
				push(@parameters, $newParameter);
			} else {
				# update values
				$p->{'_codeObject'}->updateValues();
				push(@parameters, $p->{'_codeObject'});
			}
		}
		return \@parameters;
	} else {
		return \@ps;
	}
}

sub get_edge_data_to {
	my ($self, $target, $graph) = @_;
	if(!defined($graph)){
		return;
	}
	return $graph->get_edge_attribute($self, $target, 'data');
}

sub get_edge_data_from {
	my ($self, $source, $graph) = @_;
	if(!defined($graph)){
		return;
	}
	return $graph->get_edge_attribute($source, $self, 'data');	
}

sub set_edge_attribute_to {
	my ($self, $target, $graph, $key, $value) = @_;
	if(!defined($graph)){
		return;
	}
	$graph->set_edge_attribute($self, $target, $key, $value);
}

sub set_edge_attribute_from {
	my ($self, $source, $graph, $key, $value) = @_;
	if(!defined($graph)){
		return;
	}
	$graph->set_edge_attribute($source, $self, $key, $value);
}

sub set_edge_data_to {
	my ($self, $target, $graph, $inMult, $outMult) = @_;
	if(!defined($graph)){
		return;
	}
	if(undef($self) || undef($target) || undef($inMult)){
		print("either self or target are undefined or not enough parameters given");
		return;
	}
	my $previous = $self->get_edge_data_to($target, $graph);
	if(undef($previous)){
		$previous = StreamGraph::Model::ConnectionData->new();
		$self->set_edge_attribute_to($target, $graph, 'data', $previous);
	}
	$previous->inputMult($inMult);
	if(!undef($outMult)){
		$previous->outputMult($outMult);
	}
}

sub set_edge_data_from {
	my ($self, $source, $graph, $inMult, $outMult) = @_;
	if(!defined($graph)){
		return;
	}
	if(undef($self) || undef($source) || undef($inMult)){
		print("either self or source are undefined or not enough parameters given");
		return;
	}
	my $previous = $self->get_edge_data_from($source, $graph);
	if(undef($previous)){
		$previous = StreamGraph::Model::ConnectionData->new();
		$self->set_edge_attribute_from($source, $graph, 'data', $previous);
	}
	$previous->inputMult($inMult);
	if(!undef($outMult)){
		$previous->outputMult($outMult);
	}
}


1;
