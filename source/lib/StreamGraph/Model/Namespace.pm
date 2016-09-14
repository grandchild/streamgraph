package StreamGraph::Model::Namespace;

use warnings;
use strict;

use Moo;

use StreamGraph::Util qw(filterNodesForType);


has filepath => ( is=>"rw", default=>"item" );
has names    => ( is=>"rw", default=>sub{()} );


sub register {
	my ($self, $name) = @_;
	push @{$self->{names}}, $name;
}

sub newname {
	my ($self, $name) = @_;
	return $self->_namespace($name);
}

sub replace {
	my ($self, $graph, $name) = @_;
	foreach my $node ($graph->get_items) {
		if ($node->isFilter) {
			my $vars = $node->globalVariables;
			my $init = $node->initCode;
			my $work = $node->workCode;
			my $old = $name;
			my $new = $self->newname($name);
			$vars =~ s/\b$old\b/$new/g;
			$init =~ s/\b$old\b/$new/g;
			$work =~ s/\b$old\b/$new/g;
			$node->globalVariables($vars);
			$node->initCode($init);
			$node->workCode($work);
		}
	}
}

sub replaceAll {
	my ($self, $graph) = @_;
	foreach my $name (@{$self->names}) {
		$self->replace($graph, $name);
	}
}


sub _namespace {
	my ($self, $name) = @_;
	return $self->_fileToPrefix . "_" . $name;
}

sub _fileToPrefix {
	my ($self) = @_;
	return $self->filepath =~ s:.*?([^/]+?)(\.sigraph)?$:$1:r =~ s/[^a-z]+$/_/gir;
}


1;
__END__

=head1 StreamGraph::Model::Namespace

Namespaces are used by StreamGraph::GraphCompat to separate potentially
identically named parameters in subgraphs from those passed in from the parent
graph. Instances of this module let you C<register> names and then, given a
graph, will replace all references to this parameter in all filters inside
that graph.

=head2 Properties

=over

=item C<$filepath> (String)

The subgraph filename, used to uniquely identify and prefix a namespace.

=item C<$names> (list[String])

The list of parameters to replace. This list is used internally and while you
could set this in the constructor, it's probably more useful to use
C<register($name)> for adding parameters.

=back

=head2 Methods

=over

=item C<StreamGraph::Model::Namespace-E<gt>new($filepath=E<gt>$filepath)>

Create a StreamGraph::Model::Namespace.

=item C<register($name)>

Registers one string parameter C<$name> into the namespace.


=item C<newname($name)>

C<return> a string with the namespace-prefixed name.

The namespace-prefixed string will have the format C<basename($filepath)."_".$name>.


=item C<replace($graph, $name)>

Replaces one C<$name> inside the given C<$graph>. The name doesn't have to be
registered and it won't be after this method is called. Most likely
C<replaceAll()> is what you want.


=item C<replaceAll($graph)>

Replaces all occurrences of all registered parameter names in all filters of
the C<$graph>.

=back
