package StreamGraph::CodeRunner;

use strict;
use Moo;
use Env qw($STREAMIT_HOME @PATH @CLASSPATH $JAVA_5_DIR);
use POSIX ":sys_wait_h";

use StreamGraph::Util::File;


has config     => ( is=>"rw", required=>1 );

has source     => ( is=>"rw" );
has ccPid      => ( is=>"rw", default=>0 );
has ccResult   => ( is=>"rw", default=>"" );
has ccResultFile => ( is=>"ro", default=>"ccResult.txt" );
has ccSuccess  => ( is=>"rw", default=>0 );
has ccSuccessFile => ( is=>"ro", default=>"ccSuccess.txt" );

has binary     => ( is=>"rw" );
has rPid     => ( is=>"rw", default=>0 );
has rResult  => ( is=>"rw", default=>"" );
has rResultFile => ( is=>"ro", default=>"runResult.txt" );
has rSuccess => ( is=>"rw", default=>0 );
has rSuccessFile => ( is=>"ro", default=>"runSuccess.txt" );


sub setStreamitEnv {
	my ($self) = @_;
	$STREAMIT_HOME = $self->config->get("streamit_home");
	$JAVA_5_DIR = $self->config->get("java_5_dir");
	push @PATH, $STREAMIT_HOME;
	push @CLASSPATH, ".";
	push @CLASSPATH, ($STREAMIT_HOME . "streamit.jar");
}

sub compile {
	my ($self, $filename) = @_;
	$self->source($filename);
	$self->_killIfNecessary(\&ccPid);
	$self->ccResult(0);
	$self->_compile();
}

sub run {
	my ($self) = @_;
	$self->_killIfNecessary(\&rPid);
	$self->_run();
}

sub isCompiling {
	my ($self) = @_;
	return (waitpid($self->ccPid, WNOHANG) != -1);
}

sub isRunning {
	my ($self) = @_;
	return (waitpid($self->rPid, WNOHANG) != -1);
}

sub compileResult {
	my ($self, $lines) = @_;
	$self->_updateCC;
	return $self->_getResult($self->ccResult, $lines);
}

sub compileSuccess {
	my ($self) = @_;
	$self->_updateCC;
	return $self->ccSuccess;
}

sub runResult {
	my ($self, $lines) = @_;
	$self->_updateRun;
	return $self->_getResult($self->rResult, $lines);
}

sub runSuccess {
	my ($self) = @_;
	$self->_updateRun;
	return $self->rSuccess;
}

sub _compile {
	my ($self) = @_;
	my $cmd = $self->config->get("base_dir") . "resources/sgstrc " . $self->config->get("streamgraph_tmp") . $self->source;
	print "Run '$cmd'\n";
	$SIG{CHLD} = "IGNORE";  # don't leave zombies of unwaited child processes, let them be reaped
	$self->ccPid(fork);
	unless($self->ccPid) {
		# system("rm -r " . $self->config->get("streamgraph_tmp"));
		chdir $self->config->get("streamgraph_tmp");
		StreamGraph::Util::File::writeFile("".`$cmd 2>&1`, $self->config->get("streamgraph_tmp") . $self->ccResultFile);
		StreamGraph::Util::File::writeFile(($? >> 8), $self->config->get("streamgraph_tmp") . $self->ccSuccessFile);  # only this shift by 8 will show the actual return value
		exit;
	}
}

sub _updateCC {
	my ($self) = @_;
	if ($self->ccResult == 0) {
		$self->ccResult(StreamGraph::Util::File::readFileAsList($self->config->get("streamgraph_tmp") . $self->ccResultFile));
		$self->ccSuccess(StreamGraph::Util::File::readFileAsList($self->config->get("streamgraph_tmp") . $self->ccSuccessFile));
	}
}

sub _run {
	my ($self) = @_;
	print "Run '" . $self->binary . "'\n";
	$SIG{CHLD} = "IGNORE";
	$self->rPid(fork);
	unless($self->rPid) {
		my $binary = $self->binary;
		$self->rResult(`$binary 2>&1`);
		$self->rSuccess($? >> 8);
		exit;
	}
}

sub _updateRun {
	my ($self) = @_;
	if ($self->rResult == 0) {
		$self->rResult(StreamGraph::Util::File::readFileAsList($self->config->get("streamgraph_tmp") . $self->rResultFile));
		$self->rSuccess(StreamGraph::Util::File::readFileAsList($self->config->get("streamgraph_tmp") . $self->rSuccessFile));
	}
}

sub _getResult {
	my ($self, $result, $lines) = @_;
	my @result = @{$result};
	if ($lines) {
		$lines = $#result if ($lines-1) > $#result;
		return join("", @result[0..$lines]);
	} else {
		return join("", @result);
	}
}

sub _killIfNecessary {
	my ($self, $process) = @_;
	$self->binary($self->config->get("streamgraph_tmp") . "a.out");
	if ($process->($self) > 0) {
		kill("TERM", $process->($self));
		kill("KILL", $process->($self));
		$process->($self, 0);
	}
}

1;
