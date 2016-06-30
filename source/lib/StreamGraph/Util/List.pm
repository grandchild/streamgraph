package StreamGraph::Util::List;

use strict;

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