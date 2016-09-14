package StreamGraph;

use 5.024000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use StreamGraph ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

1;
__END__

=head1 StreamGraph

StreamGraph is a graphical frontend to the StreamIt language. This is the main
package which contains all code apart from the executable. The code is
structured as such:


=head2 Model

Modules in the Model package are mostly data classes and present the
structural layout of this code. Node objects handle the various types of graph
items that StreamGraph has and CodeObject is the basis for the work that
CodeGen does when generating StreamIt code. You could see them as "before" and
"after" representations of the code.


=head2 View

The code in the View package is mostly the Gtk2::Ex::MindMapView which was
heavily modified in a few places (e.g. C<View>, C<Graph>, C<HotSpot>) and
mostly left as-is in others (e.g. C<Border>) and sometimes simply disabled
and/or deleted (e.g. the automatic layouting).

The classes that were not modified by us are left out of the technical
documentation, but are still documented in the source and (in their original
form) at the Gtk2::Ex::MindMapView project and can be looked up there.

Owing to the integrated nature of Gtk2::Ex::MindMapView the View also takes on
much of the control and data flow tasks. View::Graph is the central graph
topology module and a wrapper around the Graph- and Graph::Directed modules.
View::HotSpot and View::Connection are responsible for most of the work needed
to connect two nodes. View::Item is a display and topology wrapper for each
node in the graph.

=head2 Code Generation

The modules GraphCompat, CodeGen and CodeRunner take care of the backend of
this program and transform and run the graph that is created via the GUI.

=head2 Util

Various utility functions and classes are collected here -- mostly file I/O
and basic data structure operations, as well as debugging helpers.
