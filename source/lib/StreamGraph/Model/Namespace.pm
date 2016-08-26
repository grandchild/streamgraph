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
