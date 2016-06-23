package StreamGraph::CodeGen;

use strict;
use StreamGraph::View::Item;
use StreamGraph::Util::File;

$StreamGraph::CodeGen::pipelineNumber = 0;
$StreamGraph::CodeGen::dividingLine = "---------------------------------------------------";

# function which generates Code out of Graph from root Node
# gets root as 1. input parameter and filename as 2.parameter
sub generateCode {
	my $node = shift;
	my $fileName = shift;
	my $programText = generateMultiLineCommentary("Generated code from project $fileName");
	# build Node list
	my @nodeList = ();
	push(@nodeList, $node, StreamGraph::View::Item::successors($node));
	# first generate all filter code
	$programText .= generateMultiLineCommentary("$StreamGraph::CodeGen::dividingLine \nSection for all Filters");
	foreach my $filterNode (@nodeList) {
		$programText .= generateFilter($filterNode);
	}

	$programText .= generateMultiLineCommentary("$StreamGraph::CodeGen::dividingLine \nSection for all Pipelines");
	$programText .= generatePipeline(\@nodeList);
	
	### TODO: write to file in extra Util function
	StreamGraph::Util::File::writeToFile($programText, $fileName);
	return $programText;
}

sub generateCommentary{
	my $commentText = shift;
	$commentText = "\n/* " . $commentText . " */\n";
	return $commentText;
}

sub generateMultiLineCommentary {
	my $commentText = shift;
	my $commentaryText = "\n/*\n * ";
	$commentText =~ s/\r?\n/\n * /g;
	$commentaryText .= $commentText;
	$commentaryText .= "\n */\n\n";
	return $commentaryText;
}

# gets filter for which the work function is to be generated
# returns String of Work function
sub generateWork {
	my $data = shift;
	my $workText = "\twork";
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
	my $workCode = $data->{workCode};
	$workCode =~ s/\r?\n/\n\t\t/g;
	$workText .= "\t\t$workCode";
	$workText .= "\n\t}\n";
	return $workText;
}

# gets NoteData objectfor which the init funktion is to be generated
sub generateInit {
	my $data = shift;
	my $initText = $data->{initCode};
	my $workText = "\tinit {";
	if(!($initText eq "")){
		$initText =~ s/\r?\n/\n\t\t/g;
		$workText .= "\n\t\t$initText";
		$workText .= "\n\t";
	}
	$workText .= "}\n";
	return $workText;
}




# gets Node as 1.parameter
# returns "" if filter is not defined and Filtertext if defined
sub generateFilter {
	my $filterNode = shift;
	if (!defined($filterNode)) {
		return "";
	}
	my $data = $filterNode->{data};
	my $inputType = $data->{inputType};
	my $outputType = $data->{outputType};
	my $name = $data->{name};
	my $globalVariables = $data->{globalVariables};
	my $filterText = generateCommentary("Filter $name") . "$inputType->$outputType filter $name {\n"; 
	if(!($globalVariables eq "")){
		$globalVariables =~ s/\r?\n/\n\t/g;
		$filterText .= "\t$globalVariables\n";
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
	my $filterPointer = shift;
	my @filterArray = @{$filterPointer};
	if (!@filterArray) {
		return "";
	}
	my $arraySize = @filterArray;
	my $inputType =  $filterArray[0]->{data}->{inputType};
	my $outputType = $filterArray[$arraySize-1]->{data}->{outputType};
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