package StreamGraph::View::ArgUtils;

use warnings;
use strict;
use Carp;

use Exporter;

our $VERSION = '0.000001';

our @ISA = qw(Exporter);

our @EXPORT = qw(args_required args_store args_valid arg_default);


sub args_required
{
    my ($attributes_ref, @valid_keys) = @_;

    foreach my $valid_key (@valid_keys)
    {
	if (!defined $attributes_ref->{$valid_key})
	{
	    croak "Missing required argument: $valid_key\n";
	}
    }
}


sub args_store
{
    my ($self, $attributes_ref) = @_;

    my %attributes = %$attributes_ref;

    foreach my $key (keys %attributes)
    {
	$self->{$key} = $attributes{$key};
    }
}


sub args_valid
{
    my ($attributes_ref, @valid_keys) = @_;

    KEY: foreach my $key (keys %$attributes_ref)
    {
	foreach my $valid_key (@valid_keys)
	{
	    next KEY if ($valid_key eq $key);
	}

	croak "Invalid argument: $key\n";
    }
}


sub arg_default
{
    my ($self, $key, $default) = @_;

    if (!defined $self->{$key})
    {
	$self->{$key} = $default;
    }
}


1; # Magic true value required at end of module
__END__

=head1 StreamGraph::View::ArgUtils

This is an internal set of argument handling utilities.

=over

=item args_required ($attributes_ref, @valid_keys)

Complains if a required argument to a module is missing.

=item args_store ($self, $attributes_ref)

Copies arguments from attributes hash to hash referenced by $self.

=item args_valid ($attributes_ref, @valid_keys)

Complains of an invalid or unexpected argument is given.

=item arg_default ($self, $key, $default)

Assigns a default value if one is needed.

=back
