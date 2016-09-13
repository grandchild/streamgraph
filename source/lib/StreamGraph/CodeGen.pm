package StreamGraph::CodeGen;

use strict;
use Data::Dump qw(dump);
use StreamGraph::View::Item;
use StreamGraph::Util::File;
use StreamGraph::Util qw(unique filterNodesForType);
use StreamGraph::Model::CodeObject::Pipeline;
use StreamGraph::Model::CodeObject::SplitJoin;


my $boxNumber = 0;
my $dividingLine = "---------------------------------------------------";
my $fileName;
my $view;

# function which generates Code out of Graph from root Node
# gets View as 1. input parameter, GraphCompat as 2. input parameter, configFile as 3.parameter and filename as 4.parameter
sub generateCode {
	$view = shift;
	if(!defined($view)){
		return 0;
	}
	my $graph = shift;
	if(!defined($graph)){
		$view->println("Graph is not valid ", 'dialog-error');
		return 0;
	}
	my $configFile = shift;
	if(!$configFile){
		$view->println("No config file found", 'dialog-error');
		return 0;
	}
	$fileName = shift;
	if(!$fileName || !defined($fileName)){
		$fileName = "main";
		$view->println("No fileName given. Setting fileName to main", 'dialog-info');
	}
	$boxNumber = 0;
	my $programText = generateMultiLineCommentary("Generated code from project $fileName");
	# build Node list
	my @nodeList = $graph->topological_sort();
	@nodeList = unique(@nodeList);
	@nodeList = @{filterNodesForType(\@nodeList, "StreamGraph::Model::Node::Filter")};
	# first generate all filter code
	$programText .= generateSectionCommentary("Section for all Filters");
	my $tempText;
	foreach my $filterNode (@nodeList) {
		$tempText = generateFilter($filterNode, $graph);
		if($tempText eq "ERROR"){
			return "ERROR";
		} else {
			$programText .= $tempText;
		}
	}
	# build data structure for code generation of topographical constructs
	my $mainPipeline = StreamGraph::Model::CodeObject::Pipeline->new(first=>$nodeList[0], graph=>$graph);
	if($mainPipeline->generate($view, 1) eq "ERROR"){
		return "ERROR";
	}
	my ($pipelinesCode, $splitJoinesCode) = $mainPipeline->buildCode("", "");

	$programText .= generateSectionCommentary("Section for all Pipelines") . $pipelinesCode; 
	if($splitJoinesCode){
		$programText .= generateSectionCommentary("Section for all Split-Joines") . $splitJoinesCode;
	}
	
	StreamGraph::Util::File::writeStreamitSource($programText, $configFile->get("streamgraph_tmp") . $fileName);
	return $programText;
}

sub generateCommentary{
	my $commentText = shift;
	$commentText = "/* " . $commentText . " */\n";
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
	my $commentaryText = "\n" . generateCommentary($dividingLine);
	$commentaryText .= generateMultiLineCommentary($commentText);
	return $commentaryText;
}

# gets filter for which the work function is to be generated
# returns String of Work function
sub generateWork {
	my $data = shift;
	my $workText = "\twork";
	my $timesPop = $data->{timesPop};
	my $timesPush = $data->{timesPush};
	my $timesPeek = $data->{timesPeek};
	if($timesPop) {
		$workText .= " pop $timesPop";
	}
	if($timesPush) {
		$workText .= " push $timesPush";
	}
	if ($timesPeek) {
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

# gets list of parameters(type is item), flag if types should be included, flag if brackets should be included in case listFlag is not set,
# flag if parameter value is added;
# and flag if a List should be returned; 
# if flags are not given or not 1 or 0 it is assumed: typeFlag = 1; bracketflag = 1; valueFlag = 0; listFlag = 0; 
# returns parameter string or List if flag is set
# list/string generateParameters(item* parameterPointer, bool typeFlag, bool bracketFlag, bool valueFlag, bool listFlag);
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
	my $valueFlag = shift;
	if(!defined($valueFlag) || $valueFlag != 1) {
		$valueFlag = 0;
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
			my $parameterName = $parameter->name;
			# check if Type should be included
			if($typeFlag == 1){
				my $parameterType = $parameter->outputType;
				$parameterText .= "$parameterType ";
			}
			$parameterText .= "$parameterName";
			if($valueFlag == 1){
				my $parameterValue = $parameter->value; 
				$parameterText .= " = $parameterValue";	
			}
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
# returns "ERROR" if filter is not defined and Filtertext if defined
sub generateFilter {
	my $filterNode = shift;
	my $graph = shift;
	if (!( defined($filterNode))  ) {
		$view->println("$filterNode is not defined", 'dialog-error');
		return "ERROR";
	}
	if(!( $filterNode->isFilter )){
		$view->println($filterNode->name . " is not a Filter", 'dialog-error');
		return "ERROR";
	}
	if($filterNode->name eq "__void_sink__" || $filterNode->name eq "__void_source__"){
		$filterNode->{'_no_add'} = 1;
		return "";
	}
	if(updateNodeName($filterNode) eq "ERROR"){
		return "ERROR";
	}
	my $inputType = $filterNode->{inputType};
	my $outputType = $filterNode->{outputType};
	my $name = $filterNode->{'_gen_name'};
	my $globalVariables = $filterNode->{globalVariables};
	my $filterText = generateCommentary("Filter $name") . "$inputType->$outputType filter $name";
	my @parameters = $graph->predecessors($filterNode, "StreamGraph::Model::Node::Parameter");
	$filterText .= generateParameters(\@parameters);
	$filterText .= " {\n"; 
	if(!($globalVariables eq "")){
		$globalVariables =~ s/\r?\n/\n\t/g;
		$filterText .= "\t$globalVariables\n";
	}
	$filterText .= generateInit($filterNode);
	$filterText .= generateWork($filterNode);
	$filterText .= "}\n\n";

	return $filterText;
}


# gets a filterNode and updates it to have a Number at end of name.
sub updateNodeName {
	my $filterNode = shift;
	if(!defined($filterNode)){
		$view->println("can not update name of undefined object", 'dialog-error');
		return "ERROR";
	}
	$filterNode->{'_gen_name'} = ( $filterNode->name . $boxNumber);
	$boxNumber++;
}

# gets a Flag if the Pipeline is the first/main pipeline
# returns Name as String
sub getTopologicalConstructName {
	my $mainFlag = shift;
	if(!defined($mainFlag) || $mainFlag != 1){
		$mainFlag = 0;
	}
	my $splitJoinText = shift;
	if(!defined($splitJoinText)){
		$splitJoinText = "";
	}
	my $text = "";
	if($mainFlag == 1){
		$text = $fileName;
	} else {
		if($splitJoinText){
			$text = "SplitJoin" . $boxNumber . $splitJoinText;
		} else {
			$text = "Pipeline" . $boxNumber;
		}
		$boxNumber++;
	}
	return $text;
}

1;

__END__

=head1 StreamGraph::CodeGen

Wrapper file for the code generation into StreamIt

=over

=item C<generateCode($view, $graph, $configFile, $fileName)>

C<return> Generated code or Error message if the generation failed.

This is a wrapper function for the code generation which gets the $view to print error messages, 
the $graph for which the code should be generated, the $configFile to write into the tmp directory
and optionally the $fileName. If the $fileName is not given the name main is assumed.


=item C<generateCommentary($commentaryText)>

C<return> comment text

Generates a comment in StreamIt code with the given text.


=item C<generateMultiLineCommentary($commentaryText)>

C<return> comment text

Generates a multiline commentary in StreamIt code with the given (multiline) text.


=item C<generateSectionCommentary($commentText)>

C<return> comment text

Generates a Section heading as a StreamIt commentary with the given text.


=item C<generateWork($data)>

C<return> code for the work function of the given filter

Expects a StreamGraph::Model::Node::Filter as input. 
Generates the code for the work function of the given filter.


=item C<generateInit($data)>

C<return> code for the init function of a filter

Expects a StreamGraph::Model::Node::Filter as input. 
Generates the code for the init function of a filter


=item C<generateParameters($parameterListPointer, $typeFlag, $bracketFlag, $valueFlag, $listFlag)>

C<return> string or list of parameter names, types and values as specified through parameters 

Expects a pointer to a list of StreamGraph::Model::Node::Parameter as first parameter.
The $listFlag specifies if the returned value should be a list if the flag is true or a complete string. 
If the $typeFlag is true then the type of the parameters in the list of parameters($parameterListPointer)
is included in the returned value. The $bracketFlag enables brackets in the begin and the end of the 
returned string when the listFlag is false, otherwise it is irrelevant. The $valueFlag if true adds 
the value of the parameters of the list($parameterListPointer) to the returned value. 



=item C<generateFilter($filterNode, $graph)>

C<return> code of the filter in StreamIt or error message.

Expects a StreamGraph::Model::Node::Filter and a StreamGraph::GraphCompat as input parameters.
Generates the complete code of a filter including it's parameters, the init-function, the work-function 
and it's filter-global variables.


=item C<updateNodeName($filterNode)>

C<return> Error or nothing

Expects a StreamGraph::Model::Node::Filter as input. Updates the name of the Node to be unique 
through adding a '_gen_name' field with the updated name. 


=item C<getTopologicalConstructName($mainFlag, $splitJoinText)>

C<return> name of the topological construct.

Generates the name of a construct. If $mainFlag is true returns name of the file, since StreamIt 
expects a construct with the name of the file as the main construct. The $splitJoinText is optional, 
but the function assumes that without an input of it ($splitJoinText) the construct for which the 
name should be generated is a pipeline. Otherwise the function assumes it is a split-join .

=back
