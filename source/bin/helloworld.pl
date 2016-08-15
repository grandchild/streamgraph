#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;
use Gnome2::Canvas;
use Carp;
use Time::HiRes qw(gettimeofday);
use YAML qw(DumpFile LoadFile Dump Bless Blessed);
use Data::Dump qw(dump);

use lib "./lib/";

use StreamGraph::View;
use StreamGraph::View::ItemFactory;
use StreamGraph::Model::NodeFactory;
use StreamGraph::GraphCompat;
use StreamGraph::CodeGen;
use StreamGraph::CodeRunner;
use StreamGraph::Util qw (getItemWithId getNodeWithId);
use StreamGraph::Util::PropertyWindow;
use StreamGraph::Util::DebugGraph;
use StreamGraph::Util::DebugCode;
use StreamGraph::Util::Config;
use StreamGraph::Util::File;


my $window   = Gtk2::Window->new('toplevel');

my $uimanager;
my $menu_edit;
my $scroller = Gtk2::ScrolledWindow->new();
$scroller->signal_connect('event',\&_window_handler);
$scroller->signal_connect('key-press-event' => \&show_key);
my $view = StreamGraph::View->new(aa=>1);
$view->set(connection_arrows=>'one-way');
$window->set_size_request(900,500);
my $menu = create_menu();
$scroller->add($view);
$window->signal_connect('destroy'=>sub { _closeapp($view); });
$window->set_type_hint('dialog');
$window->add($menu);
$menu->add($scroller);

my $factory = StreamGraph::View::ItemFactory->new(view=>$view);
my $nodeFactory = StreamGraph::Model::NodeFactory->new();
my $config = StreamGraph::Util::Config->new();

$view->{saveFile} = shift or die "Usage: $0 [filename]\n";
loadFile($view->{saveFile});

# codeGenShow();
# runShow();

$window->signal_connect('leave-notify-event',
	sub { if (defined $view->{toggleCon}) {
			$view->{toggleCon}->{predecessor_item}->{hotspots}->{'toggle_right'}->end_connection;
	}	} );

$window->show_all();
$view->set_scroll_region(-1000,-1000,1000,1000);
scroll_to_center();

Gtk2->main();

exit 0;

sub _closeapp {
	my $view = shift(@_);
	$view->destroy();
	Gtk2->main_quit();
	return 0;
}

sub scroll_to_center{
	my ($sx1, $sy1, $sx2, $sy2) = $view->get_scroll_region();
	my ($width,$height) = $window->get_size();
	my $x = ($sx2 - $sx1 - $width)/2;
	my $y = ($sy2 - $sy1 - $height)/2;
	$view->scroll_to($x,$y);
}

sub _test_handler {
	my ($item, $event) = @_;
	# print "item: $item  event: $event\n";
	my $event_type = $event->type;
	my @coords = $event->coords;
	# print $item . "Event, type: $event_type  coords: @coords\n";

	if ($event_type eq 'button-press' && $event->button == 1) {
		$item->{x_prime} = $coords[0];
		$item->{y_prime} = $coords[1];
		$view->deselect;
		$item->select(1);
		unshift (@{$view->{focusItem}},$item);
	} elsif ($event_type eq 'motion-notify') {
		unless (defined $item->{y_prime}) {return;}
		$item->set(x=>($item->get('x') + ($coords[0] - $item->{x_prime}) ));
		$item->set(y=>($item->get('y') + ($coords[1] - $item->{y_prime}) ));
		$item->{x_prime} = $coords[0];
		$item->{y_prime} = $coords[1];
	}	elsif ($event_type eq 'button-press' && $event->button == 3) {
		$view->{popup} = 1;
		$item->select(1);
		unshift (@{$view->{focusItem}},$item);
	} elsif ($event_type eq '2button-press' && $event->button == 1) {
		StreamGraph::Util::PropertyWindow::show($item,$window);
	}
	if ($event_type eq 'button-release') {
		undef $item->{x_prime};
		undef $item->{y_prime};
	}
}

sub _window_handler {
    my ($win, $event) = @_;
    my $event_type = $event->type;
    my @coords = $event->coords;

		if ($event_type eq 'button-press' && $event->button == 1) {
			if ($#{$view->{focusItem}}+1 && defined $view->{focusItem}->[0]->{x_prime}) { return; }
			my @rcoords = $event->root_coords;
			$view->{x_prime} = $rcoords[0];
			$view->{y_prime} = $rcoords[1];
			$view->deselect;
		} elsif ($event_type eq 'button-press' && $event->button == 3) {
			if ($view->{popup}) {	return;	}
			$view->{x1_rect} = $coords[0];
			$view->{y1_rect} = $coords[1];
			$view->{selectBox} = Gnome2::Canvas::Item->new(
				$view->root,
				'Gnome2::Canvas::Rect',
				fill_color_gdk    => Gtk2::Gdk::Color->parse('lightgray'),
				outline_color_gdk => Gtk2::Gdk::Color->parse('gray'),
			);
			$view->{selectBox}->lower_to_bottom;
		} elsif ($event_type eq 'motion-notify') {
			if (defined $view->{selectBox}) {
				my ($fx,$fy,$tx, $ty) = $view->get_scroll_region();
				$view->{selectBox}->set(x1=>$view->{x1_rect} + $fx);
				$view->{selectBox}->set(y1=>$view->{y1_rect} + $fy);
				$view->{selectBox}->set(x2=>$coords[0] + $fx);
				$view->{selectBox}->set(y2=>$coords[1] + $fy);
				$view->deselect();
				for my $it ($view->{graph}->{graph}->vertices()){
					my ($x1,$x2,$y1,$y2) = $view->{selectBox}->get('x1','x2','y1','y2');
					($x1,$x2) = $x1 < $x2 ? ($x1,$x2) : ($x2,$x1);
					($y1,$y2) = $y1 < $y2 ? ($y1,$y2) : ($y2,$y1);
					my $inside = 	$it->get('x') > $x1 &&
												$it->get('x') < $x2 &&
												$it->get('y') > $y1 &&
												$it->get('y') < $y2;
					if ( $inside ){
						unshift (@{$view->{focusItem}},$it);
						$it->select(1);
					}
				}
			}
			unless (defined $view->{y_prime}) {return;}
			my ($cx, $cy) = $view->get_scroll_offsets();
			my @rcoords = $event->root_coords;
			$view->scroll_to($cx + ($view->{x_prime} - $rcoords[0]) , $cy + ($view->{y_prime} - $rcoords[1]) );
			$view->{x_prime} = $rcoords[0];
			$view->{y_prime} = $rcoords[1];
			$window->show_all;
		}
		if ($event_type eq 'button-release') {
			undef $view->{x_prime};
			undef $view->{y_prime};
		}
		if ($event_type eq 'button-release' && $event->button == 3) {
			if (defined $view->{selectBox}) {
				my $returnVal = $view->{selectBox}->get('x1') - $view->{selectBox}->get('x2');
				$view->{selectBox}->destroy();
				undef $view->{selectBox};
				return if $returnVal;
			}
			if ($view->{popup}) {	$view->{popup} = 0;	return;	}
			my @coords = $event->coords;
			$view->{menuCoordX} =  $coords[0];
			$view->{menuCoordY} =  $coords[1];
			$menu_edit->popup(undef, undef, undef, undef, $event->button, 0);
		}
}

sub graphViz {
	my $graphCompat = StreamGraph::GraphCompat->new($view->{graph});
	StreamGraph::Util::DebugGraph::export_graph($window,$view,$graphCompat,$config->get('streamgraph_tmp'));
}

sub codeGenShow {
	my $graphCompat = StreamGraph::GraphCompat->new($view->{graph});
	StreamGraph::Util::DebugCode::show_code(
		$window, $view,
		StreamGraph::CodeGen::generateCode($graphCompat, "", $config)
	);
}

sub runShow {
	my $runner = StreamGraph::CodeRunner->new(config=>$config);
	$runner->setStreamitEnv($config);
	$runner->compileAndRun("main.str", sub{ print $runner->runResult(10); });
}

sub addItem {
	my ($node, $placeUnderMenu) = @_;
	my $item;
	if ($node->isa("StreamGraph::Model::Node::Filter")) {
		$item = addFilter($node);
	} elsif ($node->isa("StreamGraph::Model::Node::Parameter")) {
		$item = addParameter($node);
	} elsif ($node->isa("StreamGraph::Model::Node::Comment")) {
		$item = addComment($node);
	} else {
		croak "Unknown node data type " . ref($node) . "\n";
	}
	$item->signal_connect(event=>\&_test_handler);
	$view->add_item($item);
	if ($placeUnderMenu and defined $view->{menuCoordX} and defined $view->{menuCoordY}) {
		my ($width, $height) = $window->get_size();
		my ($fx,$fy,$tx, $ty) = $view->get_scroll_region();
		$item->set(x=> ($view->{menuCoordX} + $fx) );
		$item->set(y=> ($view->{menuCoordY} + $fx) );
	}
	return $item;
}

sub addFilter {
	my ($node) = @_;
	my $item = $factory->create_item(border=>'StreamGraph::View::Border::RoundedRect',
					content=>'StreamGraph::View::Content::EllipsisText',
					text=>$node->name,
					font_desc=>Gtk2::Pango::FontDescription->from_string("Vera Sans italic 8"),
					hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
					# outline_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
					fill_color_gdk =>Gtk2::Gdk::Color->parse('white'),
					data=>$node);
	return $item;
}

sub addParameter {
	my ($node) = @_;
	my $item = $factory->create_item(border=>'StreamGraph::View::Border::Rectangle',
					content=>'StreamGraph::View::Content::EllipsisText',
					text=>$node->value,
					font_desc=>Gtk2::Pango::FontDescription->from_string("Vera Sans 8"),
					hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
					outline_color_gdk=>Gtk2::Gdk::Color->parse('lightgray'),
					fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'),
					data=>$node);
	return $item;
}

sub addComment {
	my ($node) = @_;
	my $item = $factory->create_item(border=>'StreamGraph::View::Border::Rectangle',
					content=>'StreamGraph::View::Content::EllipsisText',
					text=>$node->string,
					font_desc=>Gtk2::Pango::FontDescription->from_string("Vera Sans 8"),
					hotspot_color_gdk=>Gtk2::Gdk::Color->parse(''),
					outline_color_gdk=>Gtk2::Gdk::Color->parse('#dfdfdf'),
					fill_color_gdk   =>Gtk2::Gdk::Color->parse('#eee'),
					data=>$node);
	return $item;
}

sub show_key {
	my ($widget,$event,$parameter) =  @_;
	if ($event->keyval eq "65535") {
		while ($#{$view->{focusItem}}+1) {
			my $it = shift @{$view->{focusItem}};
			$view->remove_item($it);
		}
	}
}

sub delConnection {
	$view->remove_connection($view->{focusConnection});
}

sub addNewFilter {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Node::Filter",
			name=>"Filter",
			workCode=>"push(pop());",
			inputType=>"int",
			inputCount=>1,
			outputType=>"int",
			outputCount=>1,
			timesPop=>1,
			timesPush=>1
		),
		1
	);
}

sub addNewParameter {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Node::Parameter",
			name=>"Parameter",
			outputType=>"int",
		),
		1
	);
}

sub addNewComment {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Node::Comment",
			name=>"Comment",
			string=>"Foo happens here"
		),
		1
	);
}

sub saveFile {
	unless (defined $view->{saveFile}) {return saveAsFile();}
	StreamGraph::Util::File::save($view->{saveFile}, $view->{graph});
	$window->set_title("StreamGraphView - " . $view->{saveFile});
}

sub saveAsFile {
	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("StreamGraph");
	$filter->add_pattern("*.sigraph");

	my $file_chooser =  Gtk2::FileChooserDialog->new (
	'Speichern',
	undef,
	'save',
	'gtk-cancel' => 'cancel',
	'gtk-ok' => 'ok'
	);
	$file_chooser->add_filter($filter);
	$file_chooser->set_do_overwrite_confirmation(TRUE);
	my $filename;

	if ('ok' eq $file_chooser->run){
		$filename = $file_chooser->get_filename;
	}

	$file_chooser->destroy;

	unless (defined $filename){ return; }

	unless ($filename =~ /.sigraph\Z/) {
		$filename .= ".sigraph";
	}
	$view->{saveFile} = $filename;
	saveFile();
}

sub openFile {
	my $filter = Gtk2::FileFilter->new();
	$filter->set_name("StreamGraph");
	$filter->add_pattern("*.sigraph");

	my $file_chooser =  Gtk2::FileChooserDialog->new (
		'Laden',
		undef,
		'open',
		'gtk-cancel' => 'cancel',
		'gtk-ok' => 'ok'
	);
	$file_chooser->add_filter($filter);

	my $filename;
	if ('ok' eq $file_chooser->run){
		$filename = $file_chooser->get_filename;
	}
	$file_chooser->destroy;
	unless (defined $filename){ return; }
	loadFile($filename);
}

sub loadFile {
	my ($filename) = @_;
	my ($nodes, $connections) = StreamGraph::Util::File::load($filename);
	$view->clear();
	my @items = map { addItem($_) } @{$nodes};
	map {
		my $data = StreamGraph::Model::ConnectionData->new;
		if ($_->{data}) {
			$data = StreamGraph::Model::ConnectionData->new($_->{data});
		}
		$view->connect(
			getItemWithId(\@items, $_->{from}),
			getItemWithId(\@items, $_->{to}),
			$data
		)
	} @{$connections};
}

sub newFile {
	$view->clear();
	undef $view->{saveFile}
}

sub create_menu {
	my $vbox = Gtk2::VBox->new(FALSE,5);
	my @entries = (
		[ "FileMenu",undef,"_Datei"],
		[ "New", 'gtk-new', undef,  "<control>N", undef, \&newFile ],
		[ "Open", 'gtk-open', undef,  "<control>O", undef, \&openFile ],
		[ "Save", 'gtk-save', undef,  "<control>S", undef, \&saveFile ],
		[ "SaveAs", 'gtk-save-as', undef,  "<shift><control>S", undef, \&saveAsFile ],
		[ "Quit", 'gtk-quit', undef,  "<control>Q", undef, undef ],
		[ "Close", 'gtk-close', undef,  "<shift>W", undef, undef ],
		[ "EditMenu",'gtk-edit'],
		[ "NewF", undef, 'Neuer Filter', undef, undef, \&addNewFilter ],
		[ "NewP", undef, 'Neuer Parameter', undef, undef, \&addNewParameter ],
		[ "NewC", undef, 'Neuer Kommentar', undef, undef, \&addNewComment ],
		[ "RunMenu", undef, "_Run"],
		[ "RunShow", undef, 'Run', "<control>R", undef, \&runShow ],
		[ "DebugMenu", undef, "_Debug"],
		[ "GraphViz", undef, 'Show GraphViz', "<control>D", undef, \&graphViz ],
		[ "CodeGenShow", undef, 'Show Streamit Code', "<shift><control>D", undef, \&codeGenShow ],
		[ "Connection", undef, undef],
		[ "DelC",'gtk-delete', undef, undef, undef, \&delConnection ],
	);
	$uimanager = Gtk2::UIManager->new;
	my $accelgroup = $uimanager->get_accel_group;
	$window->add_accel_group($accelgroup);
	my $actions_basic = Gtk2::ActionGroup->new ("actions_basic");
	$actions_basic->add_actions(\@entries, undef);
	$uimanager->insert_action_group($actions_basic,0);

	$uimanager->add_ui_from_string (
	"<ui>
		<menubar name='MenuBar'>
			<menu action='FileMenu'>
				<menuitem action='New'/>
				<menuitem action='Open'/>
				<separator/>
				<menuitem action='Save'/>
				<menuitem action='SaveAs'/>
				<separator/>
				<menuitem action='Quit'/>
			</menu>
			<menu action='EditMenu'>
				<menuitem action='NewF'/>
				<menuitem action='NewP'/>
				<menuitem action='NewC'/>
			</menu>
			<menu action='RunMenu'>
				<menuitem action='RunShow'/>
			</menu>
			<menu action='DebugMenu'>
				<menuitem action='GraphViz'/>
				<menuitem action='CodeGenShow'/>
			</menu>
		</menubar>
		<menubar name='UnVisible'>
			<menu action='Connection'>
				<menuitem action='DelC'/>
			</menu>
		</menubar>
	</ui>"
	);

	my $menubar = $uimanager->get_widget('/MenuBar');
	my %menus;
	$menu_edit = $uimanager->get_widget('/MenuBar/EditMenu')->get_submenu;
	$menus{connection} = $uimanager->get_widget('/UnVisible/Connection')->get_submenu;
	$view->{menu} = \%menus;
	$vbox->pack_start($menubar,FALSE,FALSE,0);

	$vbox->show_all();
	return $vbox;
}


1;
