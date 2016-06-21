#!/usr/local/bin/perl -w
use strict;
use Gtk2::Ex::MindMapView::Item;

package codeGen;

$pipelineNumber = 0;

# function which generates Code out of Graph from root Node
# gets root as 1. input parameter and filename as 2.parameter
sub generateCode {
	my $node = shift;
	my $fileŃame = shift;
	my $programText = "\\*\n * Generated code from project $fileName\n *\\\n";
	# build Node list
	my @nodeList = push($node, Gtk2::Ex::MindMapView::Item::successors($node));
	# first generate all filter code
	foreach my $filterNode (@nodeList) {
		$programText .= generateFilter($filterNode);
	}
	$programText .= generatePipeline(@nodeList);
	# last write all code to the file
	open(my $fh, '>', $fileName);
	print $fh $programText;
	close $fh; 
}



# gets NodeData for which the work function is to be generated
# returns String of Work function
sub generateWork {
	my $filter = shift;
	my $workText = "work ";
	# needs finished when Datastructure is there
	my $timesPop = $filter->timesPop;
	my $timesPush = $filter->timesPush;
	my $timesPeek = $filter->timesPeek;
	my $filterText = $filter->filterText;
	if($timesPop > 0){
		$workText .= "pop $timesPop ";
	}
	if($timesPush > 0){
		$workText .= "push $timesPush ";
	}
	if ($timesPeek > 0) {
		$workText .= "peek $timesPeek";
	}
	$workText .= "{\n";
	$workText .= filterText;
	$workText .= "\n}\n";


}

# gets NoteData objectfor which the init funktion is to be generated
sub generateInit {
	my $filter = shift;
	my $initText = $filter->initText;
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

	# needs finished when Datastructure is there
	my $inputType = $filterNode->NodeData->inputType;
	my $outputType = $filterNode->NodeData->outputType;
	my $name = $filterNode->NodeData->name;
	my $globalVariables = $filterNode->NodeData->globalVariables;
	my $workText = "$inputType";
	$workText .= "->";
	$workText .= "$outputType filter $name {\n";
	if(!($globalVariables eq "")){
		$workText .= "$globalVariables\n";
	}
	$workText .= generateInit($filterNode->NodeData);
	$workText .= generateFilter($filterNode->NodeData);
	$workText .= "}\n";

	return workText;
}



# gets (at the moment) no parameters
sub getPipelineName {
	my $text = "Pipeline";
	$text .= "$pipelineNumber";
	$pipelineNumber++;
	return $text;
}



# generates Pipeline Text
# gets list/array of Nodes to be included in the pipeline
# returns pipeline code
sub generatePipeline {
	my @filterArray = shift;
	if (!defined(@filterArray)) {
		return "";
	}
	my $arraySize = @filterArray;
	my $inputType =  $filterArray[0]->NodeData->inputType;
	my $outputType = $filterArray[$arraySize-1]->NodeData->outputType ;
	my $workText = "inputType";
	$workText .= "->";
	$workText .= "$outputType pipeline ";
	$workText .= getPipelineName();
	$workText .= "{\n";
	foreach my $filterNode (@filterArray) {
		my $name = $filterNode->NodeData->name;
		$workText .= "add $name;\n";
	}
	$workText .= "}\n"
	return $workText;
}

1;