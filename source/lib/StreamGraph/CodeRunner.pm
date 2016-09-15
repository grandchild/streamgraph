package StreamGraph::CodeRunner;

use strict;
use Moo;
use Env qw($STREAMIT_HOME @PATH @CLASSPATH $JAVA_5_DIR);
use POSIX ":sys_wait_h";
use Data::Dump qw(dump);

use StreamGraph::Util::File;


has config        => ( is=>"rw", required=>1 );

has source        => ( is=>"rw" );
has ccPid         => ( is=>"rw", default=>0 );
has ccResult      => ( is=>"rw" );
has ccResultFile  => ( is=>"ro", default=>"ccResult.txt" );
has ccSuccess     => ( is=>"rw", default=>0 );
has ccSuccessFile => ( is=>"ro", default=>"ccSuccess.txt" );

has binary        => ( is=>"rw" );
has rPid          => ( is=>"rw", default=>0 );
has rResult       => ( is=>"rw" );
has rResultFile   => ( is=>"ro", default=>"runResult.txt" );
has rSuccess      => ( is=>"rw", default=>0 );
has rSuccessFile  => ( is=>"ro", default=>"runSuccess.txt" );


sub setStreamitEnv {
	my ($self) = @_;
	$STREAMIT_HOME = $self->config->get("streamit_home");
	$JAVA_5_DIR = $self->config->get("java_5_dir");
	push @PATH, $STREAMIT_HOME;
	push @CLASSPATH, ".";
	push @CLASSPATH, ($STREAMIT_HOME . "streamit.jar");
	$self->binary($self->config->get("streamgraph_tmp") . "a.out");
}

sub compileAndRun {
	my ($self, $filename, $callback) = @_;
	$self->compile($filename, sub{
		if ($self->compileSuccess != 0) {
			$self->rSuccess(-1);
			$callback->();
		} else {
			$self->run($callback);
		}
	});
}

sub compile {
	my ($self, $filename, $callback) = @_;
	$self->source($filename);
	$self->_killIfNecessary(\&ccPid);
	$self->ccSuccess(-1);
	$self->_compile();
	$self->_after($self->ccPid, $callback);
}

sub run {
	my ($self, $callback) = @_;
	$self->_killIfNecessary(\&rPid);
	$self->rSuccess(-1);
	$self->_run;
	$self->_after($self->rPid, $callback);
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

sub compileErrors {
	my ($self) = @_;
	$self->_updateCC;
	my @result = @{$self->ccResult};
	return join("", grep(/^streamit.+/, @result));
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
	if ($self->ccSuccess == -1) {
		$self->ccResult(StreamGraph::Util::File::readFileAsList($self->config->get("streamgraph_tmp") . $self->ccResultFile));
		$self->ccSuccess(int(StreamGraph::Util::File::readFile($self->config->get("streamgraph_tmp") . $self->ccSuccessFile)));
	}
}

sub _run {
	my ($self) = @_;
	$self->rPid(fork);
	unless($self->rPid) {
		my $binary = $self->binary;
		StreamGraph::Util::File::writeFile("".`$binary 2>&1`, $self->config->get("streamgraph_tmp") . $self->rResultFile);
		StreamGraph::Util::File::writeFile(($? >> 8), $self->config->get("streamgraph_tmp") . $self->rSuccessFile);  # only this shift by 8 will show the actual return value
		exit;
	}
}

sub _updateRun {
	my ($self) = @_;
	if ($self->rSuccess == -1) {
		$self->rResult(StreamGraph::Util::File::readFileAsList($self->config->get("streamgraph_tmp") . $self->rResultFile));
		$self->rSuccess(int(StreamGraph::Util::File::readFile($self->config->get("streamgraph_tmp") . $self->rSuccessFile)));
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

sub _after {
	my ($self, $pid, $callback) = @_;
	return if $pid < 0;
	my $childpid = waitpid($pid, 0);
	# waitpid seems to always return -1 after the process
	# dies, and so a check is useless, even wrong
	$callback->();
}

sub _killIfNecessary {
	my ($self, $process) = @_;
	if ($process->($self) > 0) {
		kill("TERM", $process->($self));
		kill("KILL", $process->($self));
		$process->($self, 0);
	}
}

1;
__END__

=head1 StreamGraph::CodeRunner

Compile and run the generated StreamIt code.

All results are written to files, including status codes etc., because the
compilation and execution is run asynchronously.

=head2 Properties

=over

=item C<config> (StreamGraph::Util::Config)

The StreamGraph config file.

=item C<source> (String)

The source code file.

=item C<ccPid> (Integer)

The compiler process' PID.

=item C<ccResult> (list[String])

The compiler output, line by line.

=item C<ccResultFile> (String)

The compiler log filename.

=item C<ccSuccess> (Integer)

The compiler process' exit code.

=item C<ccSuccessFile> (String)

The filename for storing the compiler process' exit code.

=item C<binary> (String)

The binary file.

=item C<rPid> (Integer)

The runner process' PID.

=item C<rResult> (list[String])

The runner output, line by line.

=item C<rResultFile> (String)

The runner log filename. 

=item C<rSuccess> (Integer)

The runner process' exit code.

=item C<rSuccessFile> (String)

The filename for storing the runner process' exit code.


=back

=head2 Methods

=over

=item C<StreamGraph::CodeRunner-E<gt>new(config=>$config)>

Create a StreamGraph::CodeRunner. The C<config> parameter is required.


=item C<setStreamitEnv()>

Set the environment from the StreamGraph config.


=item C<compileAndRun($filename, $callback)>

Compile the StreamIt code and then execute it. When finished run C<$callback>.
Returns immediately.


=item C<compile($filename, $callback)>

Compile the StreamIt code. When finished run C<$callback>.
Returns immediately.


=item C<run($callback)>

Run the StreamIt binary produced by the compiler. When finished run
C<$callback>. Returns immediately.


=item C<isCompiling()>

C<return> Boolean

Check if compiler is still running.


=item C<isRunning()>

C<return> Boolean

Check if runner is still running.


=item C<compileResult($lines)>

C<return> the result of the compiler (list[String])

If C<$lines> (Integer) is given, return only the first C<$lines> result lines.


=item C<compileSuccess()>

C<return> the compiler exit code (Integer)


=item C<compileErrors()>

C<return> errors in the compiler output (list[String])

Returns only the lines from the output that are actual error locations and not
the java stacktrace.



=item C<runResult($lines)>

C<return> the result of the runner (list[String])

If C<$lines> (Integer) is given, return only the first C<$lines> result lines.


=item C<runSuccess()>

C<return> the runner exit code (Integer)


=item C<_compile()>

Fork and execute the compilation process.


=item C<_updateCC()>

Update all compiler relevant fields (C<$self-E<gt>cc*>).


=item C<_run()>

Fork and execute the runner process.

=item C<_updateRun()>

Update all runner relevant fields (C<$self-E<gt>r*>).


=item C<_getResult($result, $lines)>

C<return> the first C<$lines> (Integer) lines from the C<$result> (list[String]).


=item C<_after($pid, $callback)>

Wait for the forked process with C<$pid> (Integer) and then call C<$callback> (Function).


=item C<_killIfNecessary($process)>

Kill the process if the PID returned by C<$process->($self)> exists.

C<$process> has to be a code ref to either C<ccPid()> or C<rPid()>.

=back
