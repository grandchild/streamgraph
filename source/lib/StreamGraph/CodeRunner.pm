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
has runPid     => ( is=>"rw", default=>0 );
has runResult  => ( is=>"rw", default=>"" );
has runResultFile => ( is=>"ro", default=>"runResult.txt" );
has runSuccess => ( is=>"rw", default=>0 );
has runSuccessFile => ( is=>"ro", default=>"runSuccess.txt" );


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
	$self->_killIfNecessary(\&runPid);
	$self->_run();
}

sub isCompiling {
	my ($self) = @_;
	return (waitpid($self->ccPid, WNOHANG) != -1);
}

sub isRunning {
	my ($self) = @_;
	return (waitpid($self->runPid, WNOHANG) != -1);
}

sub compileResult {
	my ($self) = @_;
	$self->_updateCC;
	return $self->ccResult;
}

sub compileSuccess {
	my ($self) = @_;
	$self->_updateCC;
	return $self->ccSuccess;
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
		StreamGraph::Util::File::writeFile($? >> 8, $self->config->get("streamgraph_tmp") . $self->ccSuccessFile);  # only this shift by 8 will show the actual return value
		exit;
	}
}

sub _updateCC {
	my ($self) = @_;
	if ($self->ccResult == 0) {
		$self->ccResult(StreamGraph::Util::File::readFile($self->config->get("streamgraph_tmp") . $self->ccResultFile));
		$self->ccSuccess(StreamGraph::Util::File::readFile($self->config->get("streamgraph_tmp") . $self->ccSuccessFile));
	}
}

sub _run {
	my ($self) = @_;
	print "Run '" . $self->binary . "'\n";
	$SIG{CHLD} = "IGNORE";
	$self->runPid(fork);
	unless($self->runPid) {
		my $binary = $self->binary;
		$self->runResult(`$binary 2>&1`);
		$self->runSuccess($? >> 8);
		exit;
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
