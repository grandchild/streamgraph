package StreamGraph::Util;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(getNodeWithId getItemWithId);


sub getNodeWithId {
	my (@nodes, $id) = @_;
	my $index = -1;
	++$index until $nodes[$index]->id eq $id;
	return \$nodes[$index];
}

sub getItemWithId {
	my ($items, $id) = @_;
	my @items = @$items;
	for (my $index = 0; $index < @items-1; $index++) {
		if ($items[$index]->{data}->id eq $id) {
			return $items[$index];
		}
	}
	return $items[$#items];
}


1;
