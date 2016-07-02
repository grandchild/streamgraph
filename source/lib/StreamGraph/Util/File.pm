package StreamGraph::Util::File;

use strict;


sub _write {
	my ($writeString, $filename) = @_;
	if(!defined($filename) || $filename eq ""){
		$filename = "a";
	}
	open(my $fh, '>', $filename);
	print $fh $writeString;
	close $fh;
}

# $file->writeFile($string, "filename.ext");
sub writeFile {
	_write(@_);
}

# $file->writeStreamitSource($string, "filename");
sub writeStreamitSource {
	my ($writeString, $filename) = @_;
	if(!(substr($filename, -4, 4) eq ".str")){
		$filename .= ".str";
	}
	_write($writeString, $filename);
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
