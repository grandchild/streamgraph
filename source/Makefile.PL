use 5.018000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'StreamGraph',
	VERSION_FROM      => 'lib/StreamGraph.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
	PREREQ_PM         => {
		'Gtk2' => '1.2498',
		'Test::More' => 0,
		'Gnome2::Canvas' => '1.002',
		'Graph' => '0.67',
		'Glib' => '1.105',
		'Moo' => '2.001001',
		'GraphViz' => '2.20',
		'YAML' => '1.15',
		'Data::Dump' => '1.23'
	},
	ABSTRACT_FROM     => 'lib/StreamGraph.pm', # retrieve abstract from module
	AUTHOR            => 'StreamGraph Group',
	LICENSE           => 'mit',
	#Value must be from legacy list of licenses here
	#http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
