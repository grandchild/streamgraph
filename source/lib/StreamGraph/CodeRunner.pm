package StreamGraph::CodeRunner;

use strict;
use Moo;
use Env qw($STREAMIT_HOME @PATH @CLASSPATH);
use POSIX ":sys_wait_h";


has config     => ( is=>"rw", required=>1 );

has source     => ( is=>"rw" );
has ccPid      => ( is=>"rw", default=>0 );
has ccResult   => ( is=>"rw", default=>"" );
has ccSuccess  => ( is=>"rw", default=>0 );

has binary     => ( is=>"rw" );
has runPid     => ( is=>"rw", default=>0 );
has runResult  => ( is=>"rw", default=>"" );
has runSuccess => ( is=>"rw", default=>0 );


sub setStreamitEnv {
	my ($self) = @_;
	$STREAMIT_HOME = $self->config->get("streamit_home");
	$STREAMIT_HOME .= substr($STREAMIT_HOME, -1) eq "/" ? "" : "/";
	push @PATH, $STREAMIT_HOME;
	push @CLASSPATH, ".";
	push @CLASSPATH, ($STREAMIT_HOME . "streamit.jar");
}

sub compile {
	my ($self, $filename) = @_;
	$self->source($filename);
	$self->_killIfNecessary(\&ccPid);
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

sub _compile {
	my ($self) = @_;
	my $cmd = $STREAMIT_HOME."strc " . $self->config->get("streamgraph_tmp")."/" . $self->source;
	print "Run '$cmd'\n";
	$SIG{CHLD} = "IGNORE";  # don't leave zombies of unwaited child processes, let them be reaped
	$self->ccPid(fork);
	unless($self->ccPid) {
		# system("rm -r " . $self->config->get("streamgraph_tmp"));
		system("mkdir -p " . $self->config->get("streamgraph_tmp"));
		system("cp " . $self->source . " " . $self->config->get("streamgraph_tmp"));
		chdir $self->config->get("streamgraph_tmp");
		my $result = `$cmd 2>&1`;
		print $result;
		$self->ccResult($result);
		$self->ccSuccess($? >> 8);  # only this shift by 8 will show the actual return value
		exit;
	}
}

sub _run {
	my ($self) = @_;
	print "Run '" . $self->binary . "'\n";
	$SIG{CHLD} = "IGNORE";
	$self->runPid(fork);
	unless($self->runPid) {
		my $binary = $self->binary;
		my $result = `$binary 2>&1`;
		print $result;
		$self->runResult($result);
		$self->runSuccess($? >> 8);
		exit;
	}
}

sub _killIfNecessary {
	my ($self, $process) = @_;
	$self->binary($self->config->get("streamgraph_tmp") . "/a.out");
	if ($process->($self) > 0) {
		kill("TERM", $process->($self));
		kill("KILL", $process->($self));
		$process->($self, 0);
	}
}

1;
