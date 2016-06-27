package StreamGraph::Util::List;

use strict;

sub unique {
	my %seen;
	return grep { !$seen{$_}++ } @_;
}

1;