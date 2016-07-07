package StreamGraph::Util::Config;

use lib qw(..);

use warnings;
use strict;
use Moo;
use YAML qw(LoadFile DumpFile Dump);
use File::Temp qw(tempdir);


has configFile => ( is=>"ro", default=>"streamgraph.conf" );
has config     => ( is=>"rw", default=>sub {undef} );
has default    => ( is=>"ro", default=>sub{
		my %hash = (
			streamit_home=>"",
			java_5_dir=>""
		);
		return \%hash;
	});


sub load {
	my $self = shift(@_);
	my $filename = $self->configFile;
	$self->createDefault if not -e $filename;
	$self->{config} = LoadFile($filename);
	$self->{config}{streamgraph_tmp} = tempdir(TMPDIR=>1, TEMPLATE=>"streamgraph_XXXXX", CLEANUP=>1);
	foreach my $key (@{[qw(streamit_home java_5_dir)]}) {
		$self->{config}{$key} .= "/" unless substr($self->{config}{$key}, -1) eq "/";
	}
}

sub write {
	my $self = shift(@_);
	my $filename = $self->configFile;
	DumpFile($filename, $self->config);
}

sub get {
	my ($self, $key) = @_;
	if(!defined($self->{config})) {
		$self->load;
	}
	return $self->{config}->{$key};
}

sub createDefault {
	my $self = shift(@_);
	$self->config($self->default);
	$self->write;
}

1;
