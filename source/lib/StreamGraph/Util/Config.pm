package StreamGraph::Util::Config;

use lib qw(..);

use warnings;
use strict;
use Moo;
use YAML qw(LoadFile DumpFile Dump);
use Data::Dump qw(dump);

has configFile => ( is=>"ro", default=>"streamgraph.conf" );
has config     => ( is=>"rw", default=>sub {undef} );
has default    => ( is=>"ro", default=>sub{
		my %hash = (streamit_home=>"", strc=>"strc");
		return \%hash;
	});


sub load {
	my $self = shift(@_);
	my $filename = $self->configFile;
	$self->createDefault if not -e $filename;
	$self->{config} = LoadFile($filename);
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
	dump($self->{config});
	return $self->{config}->{$key};
}

sub createDefault {
	my $self = shift(@_);
	$self->config($self->default);
	$self->write;
}

1;
