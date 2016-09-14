package StreamGraph::Util::Config;

use lib qw(..);

use warnings;
use strict;
use Moo;
use YAML qw(LoadFile DumpFile Dump);
use File::Temp qw(tempdir);
use File::Basename;
use File::Spec;


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
	$self->{config}{base_dir} = File::Spec->rel2abs(dirname($0)."/..");
	
	foreach my $key (@{[qw(streamit_home java_5_dir base_dir streamgraph_tmp)]}) {
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

__END__

=head1 StreamGraph::Util::Config

A utility class that implements the config file and its usage. 
The configuration file is needed for temporary dumps of the 
program, as well as and perhaps more importantly for the 
execution of the generated StreamIt program.

=head2 Properties

=over

=item C<configFile> (String)

The filename of the configuration file.

=item C<config> (Hash)

The hash with the necessary information, like directories.

=item C<default> (Hash)

The default entries for the config hash if no configuration 
file exists.

=back

=head2 Methods

=over

=item C<StreamGraph::Util::Config-E<gt>new(configFile=E<gt>$configFile, config=E<gt>$config, default=E<gt>$default)>

Create a StreamGraph::Util::Config. Set the config file location or use
without parameters to use the default location of C<"streamit.conf">, i.e. in
the working directory.


=item C<load()>

Loads the configuration file specified in the C<configFile> 
field into the C<config> field. 


=item C<write()>

Writes the configuration file specified in C<config> to the file specified in
C<configFile>.


=item C<get($key)>

C<return> the value for a given C<$key>.


=item C<createDefault()>

Sets the default config values and writes them. It is used if the given config
file does not exist.

=back
