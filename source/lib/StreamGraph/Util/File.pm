package StreamGraph::Util::File;

use strict;
use warnings;
use Carp;

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
	my @userinfo = getpwuid $<;
	my %meta = (
		name=>$filename=~s:(.*/)?([^/]+)(\.sigraph)$:$2:r,
		author=>$userinfo[0],
		formatversion=>"0.1"
	);
	my @nodes =
		map {
			{ type=>ref($_->{data}), data=>$_->{data} }
		} $graph->get_items;
	my @connections =
		map {
			my $pred = $_->[0];
			my $succ = $_->[1];
			{
				from=>$pred->{data}->id,
				to=>$succ->{data}->id,
				data=>$pred->{graph}->get_edge_attribute($pred, $succ, "data")
			}
		} $graph->get_connections;
	my $savestruct = { %meta, nodes=>\@nodes, connections=>\@connections };
	Bless($savestruct)->keys( [qw(formatversion name author nodes connections)]);  # force this key ordering
	DumpFile($filename, ("Streamit Graph File", $savestruct));
}

# Util::File::load($filename)
sub load {
	my ($filename) = @_;
	my $obj = LoadFile($filename);
	my $formatversion = "0.1";
	if((not defined $obj->{formatversion}) or (not $obj->{formatversion}=~m/^(\d+\.)*\d+$/)) {
		print "Cannot determine file format version from file, assuming v$formatversion.\n";
		$formatversion = "v" . $formatversion=~s/\./_/gr;
	} else {
		$formatversion = "v" . ($obj->{formatversion}=~s/\./_/gr);
	}
	my $dispatch = {
		# v0_2    => \&load_v0_2,
		v0_1    => \&load_v0_1
	};
	exists $dispatch->{$formatversion} or croak "Unknown file format version: $formatversion.\n";
	return $dispatch->{$formatversion}->($obj);
}
sub load_v0_1 {
	my ($obj) = @_;
	my $nodeFactory = StreamGraph::Model::NodeFactory->new;
	my @nodes =
		map {
			my $type = $_->{type};
			my $parameters = $_->{data};
			$nodeFactory->createNode(type=>$type, %{$parameters});
		} @{$obj->{nodes}};
	my @connections =
		map {
			( $_->{from}, $_->{to}, $_->{data} )
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
