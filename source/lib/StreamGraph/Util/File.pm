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
	return join("", @{_read(@_)});
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
	my ($filename, $graph, $window) = @_;
	my @userinfo = getpwuid $<;
	my ($w, $h) = $window->get_size;
	my ($x, $y) = $window->get_position;
	my %meta = (
		name=>$filename=~s:(.*/)?([^/]+)(\.sigraph)$:$2:r,
		author=>$userinfo[0],
		formatversion=>"0.2"
	);
	my %windowdata = (w=>$w, h=>$h, x=>$x, y=>$y);
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
	my $savestruct = { %meta, window=>\%windowdata, nodes=>\@nodes, connections=>\@connections };
	Bless($savestruct)->keys( [qw(formatversion name author window nodes connections)]);  # force this key ordering
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
		# v0_3    => \&load_v0_3,
		v0_2    => \&load_v0_2,
		v0_1    => \&load_v0_1
	};
	exists $dispatch->{$formatversion} or croak "Unknown file format version: $formatversion.\n";
	return $dispatch->{$formatversion}->($obj);
}
sub load_v0_2 {
	my ($obj) = @_;
	my $nodeFactory = StreamGraph::Model::NodeFactory->new;
	my %windowdata = %{$obj->{window}};
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
	return (\%windowdata, \@nodes, \@{$obj->{connections}});
}
sub load_v0_1 {
	my ($obj) = @_;
	my $nodeFactory = StreamGraph::Model::NodeFactory->new;
	my %windowdata = (w=>900, h=>500, x=>10, y=>10);
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
	return (\%windowdata, \@nodes, \@{$obj->{connections}});
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
__END__

=head1 StreamGraph::Util::File

File serialization for StreamGraph. Write and read operations for the .sigraph
YAML file format and generic file I/O.


=head2 Functions

=over

=item C<writeFile($string, $filename)>

Writes C<$string> to C<$filename>.


=item C<readFile($filename)>

C<return> contents of C<$filename> (String).


=item C<readFileAsList($filename)>

C<return> contents of C<$filename> (list[String]) line by line.


=item C<writeStreamitSource($writeString, $filename)>

Writes C<$writeString> to C<$filename>, appending ".str" suffix if
C<$filename> doesn't already have it.

Defaults to C<"a.str"> if C<$filename> is not given.


=item C<save($filename, $graph, $window)>

Serializes and saves a StreamGraph C<$graph> and its C<$window>'s properties
to C<$filename>.


=item C<load($filename)>

C<return> a tuple C<(%windowdata, @nodes, @connections)> representing the graph.

Loads a StreamGraph C<.sigraph> file into a list of nodes, a list of
connections and some window properties that can be easily added to a graph.

It detects the file format version and dispatches to a version-specific
C<load_*()> (see below).


=item C<load_v0_2($obj)>

C<return> I<same as> C<load()>

Loads the .sigraph YAML file format version 0.2.


=item C<load_v0_1($obj)>

C<return> I<same as> C<load()>

Loads the .sigraph YAML file format version 0.1 and older.


=item C<_write($writeString, $filename)>

Write a string to a file.


=item C<_read($filename)>

C<return> a list of lines (list[String]) from a file.


=back
