package StreamGraph::Util::File;

use strict;
use warnings;
use YAML qw(LoadFile DumpFile Load Dump Bless Blessed);
use Data::Dump qw(dump);

use StreamGraph::Model::NodeFactory;


# $file->writeFile($string, "filename.ext");
sub writeFile {
	_write(@_);
}

sub readFile {
	return join("", _read(@_));
}

sub readFileAsList {
	return _read(@_);
}

# $file->writeStreamitSource($string, "filename");
sub writeStreamitSource {
	my ($writeString, $filename) = @_;
	if(!defined($filename) || $filename eq ""){
		$filename = "a";
	}
	if(!(substr($filename, -4, 4) eq ".str")){
		$filename .= ".str";
	}
	_write($writeString, $filename);
}

# Util::File::save($filename, $graph);
sub save {
	my ($filename, $graph) = @_;
	my @nodes =
		map {
			# print $_->{data} . "\n";
			{ type=>ref($_->{data}), data=>$_->{data} }
		} $graph->get_items;
	my @connections =
		map {
			# print $_->[0]->{data} . " -----> " . $_->[1]->{data} . "\n";
			{ from=>$_->[0]->{data}->id, to=>$_->[1]->{data}->id }
		} $graph->get_connections;
	my $savestruct = { nodes=>\@nodes, connections=>\@connections };
	Bless($savestruct)->keys(["nodes", "connections"]);  # force this key ordering
	DumpFile($filename, ("Streamit Graph File", $savestruct));
}

# Util::File::load($filename)
sub load {
	my ($filename) = @_;
	my $nodeFactory = StreamGraph::Model::NodeFactory->new;
	my $obj = LoadFile($filename);
	my @nodes =
		map {
			my $type = $_->{type};
			my $parameters = $_->{data};
			$nodeFactory->createNode(type=>$type, %{$parameters});
		} @{$obj->{nodes}};
	my @connections =
		map {
			( $_->{from}, $_->{to} )
		} @{$obj->{connections}};
	return (\@nodes, \@{$obj->{connections}});
}

sub _write {
	my ($writeString, $filename) = @_;
	open(my $fh, '>', $filename);
	print $fh $writeString;
	close $fh;
}

sub _read {
	my ($filename) = @_;
	open(my $fh, '<', $filename);
	my @lines = <$fh>;
	close $fh;
	return \@lines;
}

1;
