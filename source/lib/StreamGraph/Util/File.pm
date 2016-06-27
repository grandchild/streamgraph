package StreamGraph::Util::File;

use strict;


sub _write {
	my $writeString = shift;
	my $fileName = shift;
	if(!defined($fileName) || $fileName eq ""){
		$fileName = "a";
	}
	open(my $fh, '>', $fileName);
	print $fh $writeString;
	close $fh;
}

# $file->writeFile($string, "filename.ext");
sub writeFile {
	_write(@_);
}

# $file->writeStreamitSource($string, "filename");
sub writeStreamitSource {
	my $writeString = shift;
	my $fileName = shift;
	if(!(substr($fileName, -4, 4) eq ".str")){
		$fileName .= ".str";
	}
	_write($writeString, $fileName);
}

# $file->writeConfig($string, "filename");
sub writeConfig {
	my $writeString = shift;
	my $fileName = shift;
	if(!(substr($fileName, -4, 4) eq ".conf")){
		$fileName .= ".conf";
	}
	_write($writeString, $fileName);
}

1;
