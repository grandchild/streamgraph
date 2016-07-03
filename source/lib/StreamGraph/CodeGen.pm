package StreamGraph::CodeGen;

use strict;
use Data::Dump qw(dump);
use StreamGraph::View::Item;
use StreamGraph::Util::File;
use StreamGraph::Util::List;

my $pipelineNumber = 0;
my $dividingLine = "---------------------------------------------------";

# function which generates Code out of Graph from root Node
# gets root (Item) as 1. input parameter and filename as 2.parameter
sub generateCode {
	my $node = shift;
	my $fileName = shift;
	my $programText = generateMultiLineCommentary("Generated code from project $fileName");
	# build Node list
	my @nodeList = StreamGraph::View::Item::all_successors($node);
	@nodeList = StreamGraph::Util::List::unique(@nodeList);
	@nodeList = @{StreamGraph::Util::List::filterNodesForType(\@nodeList, "StreamGraph::Model::Filter")};
	# first generate all filter code
	$programText .= generateSectionCommentary("Section for all Filters");
	foreach my $filterNode (@nodeList) {
		$programText .= generateFilter($filterNode);
	}

	$programText .= generateSectionCommentary("Section for all Pipelines");
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

sub generateSectionCommentary {
	my $commentText = shift;
	my $commentaryText = generateCommentary($dividingLine);
	$commentaryText .= generateMultiLineCommentary($commentText);
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

# gets list of parameters(type is item), flag if types should be included, flag if brackets should be inluded
# and flag if  a List should be returned; both is assumed as standard; 
# returns parameter string or List if flag is set
# list/string generateParameters(item* parameterPointer, bool typeFlag, bool bracketFlag, bool listFlag);
sub generateParameters {
	# initialization
	my $parameterPointer = shift;
	my $typeFlag = shift;
	if (!defined($typeFlag) || $typeFlag != 0) {
		$typeFlag = 1;
	}
	my $bracketFlag = shift;
	if (!defined($bracketFlag) || $bracketFlag != 0) {
		$bracketFlag = 1;
	}
	my $listFlag = shift;
	if (!defined($listFlag) || $listFlag != 1) {
		$listFlag = 0;
	}
	my @parameters = @{$parameterPointer};
	my $nmbParameters = @parameters;
	my $workText = "";
	my @parameterList = ();

	# building parameter list/ parameter text
	if(@parameters && $nmbParameters != 0){
		foreach my $parameter (@parameters) {
			my $parameterText = "";
			$nmbParameters--;
			my $parameterName = $parameter->{data}->name;
			# check if Type should be included
			if($typeFlag == 1){
				my $parameterType = $parameter->{data}->outputType;
				$parameterText .= "$parameterType ";
			}
			$parameterText .= "$parameterName";
			$workText .= $parameterText;
			push(@parameterList, $parameterText);
			if($nmbParameters != 0){
				$workText .= ", ";
			}
		}
		if ($bracketFlag == 1) {
			$workText ="(" . $workText . ")";
		}
	}
	if ($listFlag == 1) {
		return \@parameterList;
	} else {
		return $workText;
	}
}


# gets Node as 1.parameter
# returns "" if filter is not defined and Filtertext if defined
sub generateFilter {
	my $filterNode = shift;
	if (!( defined($filterNode))  ) {
		print "$filterNode is not defined \n";
		return "";
	}
	if(!( $filterNode->{data}->isa("StreamGraph::Model::Filter") )){
		print "filterNode->data is not a Filter\n";
		return "";
	}
	my $data = $filterNode->{data};
	my $inputType = $data->{inputType};
	my $outputType = $data->{outputType};
	my $name = $data->{name};
	my $globalVariables = $data->{globalVariables};
	my $filterText = generateCommentary("Filter $name") . "$inputType->$outputType filter $name";
	my @predecessors = StreamGraph::View::Item::predecessors($filterNode);
	my @parameters = @{StreamGraph::Util::List::filterNodesForType(\@predecessors, "StreamGraph::Model::Parameter")};
	# Todo: make names unique!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
	my @pipelineParameters = ();
	my $alreadyAddedAtLeastOneParameterFlag = 0;
	foreach my $filterNode (@filterArray) {
		# only add if element is Filter
		if($filterNode->{data}->isa("StreamGraph::Model::Filter")){
			my $name = $filterNode->{data}->{name};
			# get Parameters of Filter
			my @predecessors = StreamGraph::View::Item::predecessors($filterNode);
			my @filterParameters = @{StreamGraph::Util::List::filterNodesForType(\@predecessors, "StreamGraph::Model::Parameter")};
			$pipelineFilters .= "\t add $name" . generateParameters(\@filterParameters, 0, 1) . ";\n";
			my @generatedParameters = @{generateParameters(\@filterParameters, 1, 0, 1)};
			if(@generatedParameters != 0){
				# merge
				push(@pipelineParameters, @generatedParameters);
				#if($alreadyAddedAtLeastOneParameterFlag == 0){
				#	$pipelineParameters .= $generatedParameters;
				#} else {
				#	$pipelineParameters .= ", " . $generatedParameters ;
				#}
				#$alreadyAddedAtLeastOneParameterFlag = 1;
			}
		}
	}
	# delete duplicates
	@pipelineParameters = StreamGraph::Util::List::unique(@pipelineParameters);
	$pipelineFilters .= "}\n";
	$pipelineHeader .= join(", ", @pipelineParameters) . ")";
	return $pipelineHeader . $pipelineFilters;
}

1;