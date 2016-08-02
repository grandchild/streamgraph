package StreamGraph::Util;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(getNodeWithId getItemWithId unique filterNodesForType);


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

sub unique {
	my %seen;
	return grep { !$seen{$_}++ } @_;
}

# filters NodeList for Node with given Type
sub filterNodesForType {
	my $listPointer = shift;
	my $type = shift;
	if(!defined($type) || !defined($listPointer)){
		return \();
	}
	my @list = @{$listPointer};
	my @returnList = ();
	foreach my $listElement (@list) {
		if ($listElement->{data}->isa($type)) {
			push(@returnList, $listElement);
		}
	}
	return \@returnList;
}


1;
