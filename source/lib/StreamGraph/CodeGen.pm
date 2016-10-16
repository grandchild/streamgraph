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

sub generateCode {
	my ($view, $graph, $configFile, $givenFileName) = @_;
	if(!defined($view)){
		return 0;
	}
	if(!defined($graph)) {
		$view->println("Graph is not valid ", 'dialog-error');
		return "ERROR";
	}
	if($graph->{success}==0){
		$view->println("Graph is not valid ", 'dialog-error');
		return "ERROR";
	}
	if(!$configFile){
		$view->println("No config file found", 'dialog-error');
		return 0;
	}
	if(!$givenFileName || !defined($givenFileName)){
		$fileName = "main";
		$view->println("No fileName given. Setting fileName to main", 'dialog-info');
	} else {
		$fileName = $givenFileName;
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


sub updateNodeName {
	my $filterNode = shift;
	if(!defined($filterNode)){
		$view->println("can not update name of undefined object", 'dialog-error');
		return "ERROR";
	}
	$filterNode->{'_gen_name'} = ( $filterNode->name . $boxNumber);
	$boxNumber++;
}

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

=head2 Functions

=over

=item C<generateCode($view, $graph, $configFile, $fileName)>

C<return> Generated code or Error message if the generation failed.

This is a wrapper function for the code generation which gets the $view to print error messages, 
the C<$graph> for which the code should be generated, the $configFile to write into the tmp directory
and optionally the C<$fileName>. If the $fileName is not given the name main is assumed.


=item C<generateCommentary($commentText)>

C<return> comment text

Generates a comment in StreamIt code with the given C<$commentText>.


=item C<generateMultiLineCommentary($commentaryText)>

C<return> comment text

Generates a multiline commentary in StreamIt code with the given (multiline) C<$commentText>.


=item C<generateSectionCommentary($commentText)>

C<return> comment text

Generates a Section heading as a StreamIt commentary with the given C<$commentText>.


=item C<generateWork($data)>

C<return> code for the work function of the given filter(C<$data>)

Expects a StreamGraph::Model::Node::Filter as input. 
Generates the code for the work function of the given filter.


=item C<generateInit($data)>

C<return> code for the init function of a filter

Expects a StreamGraph::Model::Node::Filter as input. 
Generates the code for the init function of a filter.


=item C<generateParameters($parameterListPointer, $typeFlag, $bracketFlag, $valueFlag, $listFlag)>

C<return> string or list of parameter names, types and values as specified through parameters 

Expects a pointer to a list[StreamGraphModel::Node::Parameter] as first parameter.
The C<$listFlag> specifies if the returned value should be a list if the flag is true or a complete string. 
If the C<$typeFlag> is true then the type of the parameters in the list of parameters(C<$parameterListPointer>)
is included in the returned value. The C<$bracketFlag> enables brackets in the begin and the end of the 
returned string when the C<$listFlag> is false, otherwise it is irrelevant. The C<$valueFlag> if true adds 
the value of the parameters of the list(C<$parameterListPointer>) to the returned value. 



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

Generates the name of a construct. If C<$mainFlag> is true returns name of the file, since StreamIt 
expects a construct with the name of the file as the main construct. The C<$splitJoinText> is optional, 
but the function assumes that without an input of it (C<$splitJoinText>) the construct for which the 
name should be generated is a pipeline. Otherwise the function assumes it is a split-join.

=back

