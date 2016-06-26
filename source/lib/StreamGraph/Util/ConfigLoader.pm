package StreamGraph::Util::ConfigLoader;

use lib qw(..);

use warnings;
use strict;
use Moo;
use JSON qw();
use Data::Dump qw(dump);


has configFile => ( is=>"ro", default=>"config.json" );
has config     => ( is=>"rw" );

sub loadConfig {
	my $self = shift(@_);
	my $filename = $self->{configFile};
	my $json_text = do {
		open(my $json_fh, "<:encoding(UTF-8)", $filename)
			or die("Can't open \$filename\": $!\n");
		local $/;
		<$json_fh>
	};
	my $json = JSON->new;
	$self->{config} = $json->decode($json_text);
}

sub get {
	my ($self, $key) = @_;
	if(!$self->{config}) {
		$self->loadConfig;
	}
	if(defined($self->{config}) &&
			defined($self->{config}->{strings}) &&
			defined($self->{config}->{strings}->{$key})) {
		return $self->{config}->{strings}->{$key};
	} else {
		return "";
	}
}

1;
