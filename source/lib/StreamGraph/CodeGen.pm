package StreamGraph::CodeGen;

use strict;
use StreamGraph::View::Item;
use StreamGraph::Util::File;

$StreamGraph::CodeGen::pipelineNumber = 0;

# function which generates Code out of Graph from root Node
# gets root as 1. input parameter and filename as 2.parameter
sub generateCode {
	my $node = shift;
	my $fileName = shift;
	my $programText = "/*\n * Generated code from project $fileName\n */\n";
	# build Node list
	my @nodeList = ();
	push(@nodeList, $node, StreamGraph::View::Item::successors($node));
	# first generate all filter code
	foreach my $filterNode (@nodeList) {
		$programText .= generateFilter($filterNode);
	}
	foreach my $filterNode (@nodeList) {
		print "\nName = $filterNode->{data}->{name}\n";
		print "Input = $filterNode->{data}->{inputType}\n";
		print "Output = $filterNode->{data}->{outputType}\n\n";
	}
	$programText .= generatePipeline(@nodeList);
	
	### TODO: write to file in extra Util function
	StreamGraph::Util::File::writeToFile($programText, $fileName);
	return $programText;
}



# gets filter for which the work function is to be generated
# returns String of Work function
sub generateWork {
	my $data = shift;
	my $workText = "work";
	# needs finished when Datastructure is there
	my $timesPop = $data->{timesPop};
	my $timesPush = $data->{timesPush};
	my $timesPeek = $data->{timesPeek};
	if($timesPop > 0) {
		$workText .= " pop $timesPop";
	}
	if($timesPush > 0) {
		$workText .= " push $timesPush";
	}
	if ($timesPeek > 0) {
		$workText .= " peek $timesPeek";
	}
	$workText .= " {\n";
	$workText .= $data->{workCode};
	$workText .= "\n}\n";


}

# gets NoteData objectfor which the init funktion is to be generated
sub generateInit {
	my $data = shift;
	my $initText = $data->{initCode};
	my $workText = "init {\n";
	$workText .= $initText;
	$workText .= "\n}\n";

}




# gets Node as 1.parameter
# returns "" if filter is not defined and Filtertext if defined
sub generateFilter {
	my $filterNode = shift;
	if (!defined($filterNode)) {
		return "";
	}
	my $data = $filterNode->{data};

	# needs finished when Datastructure is there
	my $inputType = $data->{inputType};
	my $outputType = $data->{outputType};
	my $name = $data->{name};
	my $globalVariables = $data->{globalVariables};
	my $filterText = "$inputType->$outputType filter $name {\n";
	if(!($globalVariables eq "")){
		$filterText .= "$globalVariables\n";
	}
	$filterText .= generateInit($data);
	$filterText .= generateWork($data);
	$filterText .= "}\n";

	return $filterText;
}



# gets (at the moment) no parameters
sub getPipelineName {
	my $text = "Pipeline";
	$text .= "$StreamGraph::CodeGen::pipelineNumber";
	$StreamGraph::CodeGen::pipelineNumber++;
	return $text;
}



# generates Pipeline Text
# gets list/array of Nodes to be included in the pipeline
# returns pipeline code
sub generatePipeline {
	my @filterArray = shift;
	if (!@filterArray) {
		return "";
	}
	my $arraySize = @filterArray;
	my $inputType =  $filterArray[0]->{data}->{inputType};
	print "$inputType";
	my $outputType = $filterArray[$arraySize-1]->{data}->{outputType};
	print "$outputType";
	my $pipelineText = "$inputType";
	$pipelineText .= "->";
	$pipelineText .= "$outputType pipeline ";
	$pipelineText .= getPipelineName();
	$pipelineText .= "{\n";
	foreach my $filterNode (@filterArray) {
		my $name = $filterNode->{data}->{name};
		$pipelineText .= "\t add $name;\n";
	}
	$pipelineText .= "}\n";
	return $pipelineText;
}

1;