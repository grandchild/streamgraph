package StreamGraph::Util::File;

use strict;

# gets string to write and name of file
sub writeToFile {
	my $writeString = shift;
	my $fileName = shift;
	if(!defined($fileName) || $fileName eq ""){
		$fileName = "a";
	}
	if(!(substr($fileName, -4, 4) eq ".str")){
		$fileName .= ".str";
	}
	open(my $fh, '>', $fileName);
	print $fh $writeString;
	close $fh;
}

1;