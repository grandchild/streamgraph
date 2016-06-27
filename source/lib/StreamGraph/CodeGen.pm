package StreamGraph::CodeGen;

use strict;
use StreamGraph::View::Item;
use StreamGraph::Util::File;

my $pipelineNumber = 0;
my $dividingLine = "---------------------------------------------------";

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
	$programText .= generateMultiLineCommentary("$dividingLine \nSection for all Filters");
	foreach my $filterNode (@nodeList) {
		$programText .= generateFilter($filterNode);
	}

	$programText .= generateMultiLineCommentary("$dividingLine \nSection for all Pipelines");
	$programText .= generatePipeline(\@nodeList);
	
	### TODO: write to file in extra Util function
	StreamGraph::Util::File::writeStreamitSource($programText, $fileName);
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
	$commentaryText .= $commentText . "\n */\n\n";
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
	$workText .= "\t\t$workCode" . "\n\t}\n";
	return $workText;
}

# gets NodeData object for which the init function is to be generated
sub generateInit {
	my $data = shift;
	my $initText = $data->{initCode};
	my $workText = "\tinit {";
	if(!($initText eq "")){
		$initText =~ s/\r?\n/\n\t\t/g;
		$workText .= "\n\t\t$initText" . "\n\t";
	}
	$workText .= "}\n";
	return $workText;
}

# gets list of parameters, flag if types should be included and flag if brackets should be inluded; both is assumed as standard; 
# returns parameter string
sub generateParameters {
	my $parameterPointer = shift;
	my $typeFlag = shift;
	if (!$typeFlag || $typeFlag != 0) {
		$typeFlag = 1;
	}
	my $bracketFlag = shift;
	if (!$bracketFlag || $bracketFlag != 0) {
		$bracketFlag = 1;
	}
	my @parameters = @{$parameterPointer};
	my $nmbParameters = @parameters;
	my $workText = ""; 	
	if(@parameters && $nmbParameters != 0){
		if($bracketFlag == 1){
			$workText .= "(";
		}
		foreach my $parameter (@parameters) {
			$nmbParameters--;
			my $parameterType;
			my $parameterName;
			if($typeFlag == 1){
				$workText .= "$parameterType";
			}
			$workText .= "$parameterName";
			if($nmbParameters != 0){
				$workText .= ", ";
			}
		}
		if ($bracketFlag == 1) {
			$workText .= ")";
		}
	}
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
	my $filterText = generateCommentary("Filter $name") . "$inputType->$outputType filter $name";
	my @parameters;
	$filterText .= generateParameters(\@parameters);
	$filterText .= " {\n"; 
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
	$text .= "$pipelineNumber";
	$pipelineNumber++;
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
	my $pipelineHeader = "$inputType" . "->" . "$outputType pipeline " . getPipelineName() . "(";
	# only generate so far because parameters need to be added  
	my $pipelineFilters = "{\n";
	my $pipelineParameters =  "";
	my $alreadyAddedAtLeastOneParameterFlag = 0;
	foreach my $filterNode (@filterArray) {
		my $name = $filterNode->{data}->{name};
		my @filterParameters;
		$pipelineFilters .= "\t add $name" . generateParameters(\@filterParameters, 0, 1) . ";\n";
		my $generatedParameters = generateParameters(\@filterParameters, 1, 0);
		if($generatedParameters ne ""){
			if($alreadyAddedAtLeastOneParameterFlag == 0){
				$pipelineParameters .= $generatedParameters;
			} else {
				$pipelineParameters .= ", " . $generatedParameters ;
			}
			$alreadyAddedAtLeastOneParameterFlag = 1;
		}
	}
	$pipelineFilters .= "}\n";
	$pipelineHeader .= $pipelineParameters . ")";
	return $pipelineHeader . $pipelineFilters;
}

1;