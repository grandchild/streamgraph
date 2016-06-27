package StreamGraph::Util::ConfigLoader;

use lib qw(..);

use warnings;
use strict;
use Moo;
use JSON qw();

my $defaultConfig = "{\n\t\"streamit_home\": \"\",\n\t\"strc\": \"strc\"\n}";

has configFile => ( is=>"ro", default=>"streamgraph.conf" );
has config     => ( is=>"rw" );

sub loadConfig {
	my $self = shift(@_);
	my $filename = $self->{configFile};
	my $json_text = do {
		$self->createNewConfig() if not -e $filename;
		open(my $json_fh, "<:encoding(UTF-8)", $filename)
			or die("Can't open or create \$filename\": $!\n");
		local $/;
		<$json_fh>
	};
	my $json = JSON->new;
	$self->{config} = $json->decode($json_text);
}

sub get {
	my ($self, $key) = @_;
	if(!defined($self->{config})) {
		$self->loadConfig;
	}
	if(defined($self->{config}) &&
			defined($self->{config}->{$key})) {
		return $self->{config}->{$key};
	} else {
		return "";
	}
}

sub createNewConfig {
	my $self = shift(@_);
	my $filename = $self->{configFile};
	open(my $fh, ">:encoding(UTF-8)", $filename);
	local $/;
	print $fh $defaultConfig;
}

1;
