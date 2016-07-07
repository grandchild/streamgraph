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
use StreamGraph::CodeGen;
use StreamGraph::CodeRunner;
use StreamGraph::Util;
use StreamGraph::Util::PropertyWindow;
use StreamGraph::Util::DebugGraph;
use StreamGraph::Util::DebugCode;
use StreamGraph::Util::Config;
use StreamGraph::Util::File;


my $window   = Gtk2::Window->new('toplevel');
$window->signal_connect('button-release-event',\&_window_handler);
$window->signal_connect('leave-notify-event',\&_window_handler);
my $uimanager;
my $menu_edit;
my $menu_filter;
my $scroller = Gtk2::ScrolledWindow->new();
my $view     = StreamGraph::View->new(aa=>1);
my $menu = create_menu();
# my $view = LoadFile("helloworld.sigraph");
$view->set(connection_arrows=>'one-way');
my $factory  = StreamGraph::View::ItemFactory->new(view=>$view);
my $nodeFactory = StreamGraph::Model::NodeFactory->new();
my $config = StreamGraph::Util::Config->new();

$view->set_scroll_region(-50,-90,100,100);
$scroller->add($view);
$window->signal_connect('destroy'=>sub { _closeapp($view); });
$window->set_default_size(400,400);
$window->set_type_hint('dialog');
$window->add($menu);
$menu->add($scroller);

loadDefaultFile();

codeGenShow();

my $runner = StreamGraph::CodeRunner->new(config=>$config);
$runner->setStreamitEnv($config);
$runner->compile("main.str");
while($runner->isCompiling) {
	sleep(1);
}
# print "" . length($runner->ccResult) . " bytes of compile output\n";
$runner->run();
# while($runner->isRunning) {
# 	sleep(1);
# }
# print "" . length($runner->runResult) . " bytes of run output\n";
# my @result = split(/\n/, $runner->runResult);
# for (my $i = 0; $i < 10; $i++) {
# 	print $result[$i] . "\n";
# }


$window->show_all();

Gtk2->main();

exit 0;


sub _closeapp {
	my $view = shift(@_);
	$view->destroy();
	Gtk2->main_quit();
	return 0;
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
	} elsif ($event_type eq 'motion-notify') {
		unless (defined $item->{y_prime}) {return;}
		$item->set(x=>($item->get('x') + ($coords[0] - $item->{x_prime}) ));
		$item->set(y=>($item->get('y') + ($coords[1] - $item->{y_prime}) ));
		$item->{x_prime} = $coords[0];
		$item->{y_prime} = $coords[1];
	}	elsif ($event_type eq 'button-release' && $event->button == 3) {
		$view->{focusItem} = $item;
		$view->{popup} = 1;
		$menu_filter->popup (undef, undef, undef, undef, $event->button, $event->time);
	} elsif ($event_type eq '2button-press' && $event->button == 1) {
		StreamGraph::Util::PropertyWindow::show($item,$window);
	} elsif ($event_type eq 'enter-notify') {
		if (defined $item->{view}->{togglePress}) {
			my $titem = $item->{view}->{togglePress};
			if ($item->{view}->{togglePress} ne $item && int (gettimeofday * 100) == $titem->{connectTime}) {
				$item->{view}->connect($titem, $item);
			}
			undef $item->{view}->{togglePress};
		}
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
		if ($event_type eq 'leave-notify') {
			if (defined $view->{toggleCon}) {
				$view->{toggleCon}->disconnect();
				$view->{toggleCon}->destroy();
				undef $view->{toggleCon};
			}
			return;
		}
		if ($view->{popup}) {
			$view->{popup} = 0;
			return;
		}
		if ($event_type eq 'button-release' && $event->button == 3) {
			my @coords = $event->coords;
			$view->{menuCoordX} =  $coords[0];
			$view->{menuCoordY} =  $coords[1];
			$menu_edit->popup(undef, undef, undef, undef, $event->button, 0);
		}
}

sub graphViz {
	StreamGraph::Util::DebugGraph::export_graph($window,$view);
}

sub codeGenShow {
	StreamGraph::Util::DebugCode::show_code(
		$window, $view,
		StreamGraph::CodeGen::generateCode($view->{graph}, "")
	);
}

sub addItem {
	my ($node, $placeUnderMenu) = @_;
	my $item;
	if ($node->isa("StreamGraph::Model::Filter")) {
		$item = addFilter($node);
	} elsif ($node->isa("StreamGraph::Model::Parameter")) {
		$item = addParameter($node);
	} elsif ($node->isa("StreamGraph::Model::Comment")) {
		$item = addComment($node);
	} else {
		croak "Unknown node data type " . ref($node) . "\n";
	}
	$item->signal_connect(event=>\&_test_handler);
	$view->add_item($item);
	if ($placeUnderMenu and defined $view->{menuCoordX} and defined $view->{menuCoordY}) {
		my ($width, $height) = $window->get_size();
		$item->set(x=> ($view->{menuCoordX} - $width/2) );
		$item->set(y=> ($view->{menuCoordY} - $height/2) );
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

sub delFilter {
	$view->remove_item($view->{focusItem});
}

sub delConnection {
	$view->remove_connection($view->{focusConnection});
}

sub addNewFilter {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Filter",
			name=>"Filter",
			workCode=>"println(pop());",
			inputType=>"int",
			inputCount=>1,
			timesPop=>1
		),
		1
	);
}

sub addNewParameter {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Parameter",
			name=>"Parameter",
			outputType=>"int",
		),
		1
	);
}

sub addNewComment {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Comment",
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

sub loadFile {
	my ($filename, $view) = @_;
	my ($nodes, $connections) = StreamGraph::Util::File::load($filename);
	$view->clear();
	my @items = map { addItem($_) } @{$nodes};
	map {
		$view->connect(
			StreamGraph::Util::getItemWithId(\@items, $_->{from}),
			StreamGraph::Util::getItemWithId(\@items, $_->{to})
		)
	} @{$connections};
}

sub loadDefaultFile {
	loadFile("helloworld.sigraph", $view);
}

sub create_menu {
	my $vbox = Gtk2::VBox->new(FALSE,5);
	my @entries = (
		[ "FileMenu",undef,"_Datei"],
		[ "New", 'gtk-new', undef,  "<control>N", undef, undef ],
		[ "Open", 'gtk-open', undef,  "<control>O", undef, \&loadDefaultFile ],
		[ "Save", 'gtk-save', undef,  "<control>S", undef, \&saveFile ],
		[ "SaveAs", 'gtk-save-as', undef,  "<shift><control>S", undef, \&saveAsFile ],
		[ "Quit", 'gtk-quit', undef,  "<control>Q", undef, undef ],
		[ "Close", 'gtk-close', undef,  "<shift>W", undef, undef ],
		[ "EditMenu",'gtk-edit'],
		[ "NewF", undef, 'Neuer Filter', undef, undef, \&addNewFilter ],
		[ "NewP", undef, 'Neuer Parameter', undef, undef, \&addNewParameter ],
		[ "NewC", undef, 'Neuer Kommentar', undef, undef, \&addNewComment ],
		[ "FilterMenu", undef, "_Filter"],
		[ "DelF",'gtk-delete', undef, undef, undef, \&delFilter ],
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
			<menu action='FilterMenu'>
				<menuitem action='DelF'/>
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
	$menu_filter = $uimanager->get_widget('/MenuBar/FilterMenu')->get_submenu;
	$menus{connection} = $uimanager->get_widget('/UnVisible/Connection')->get_submenu;
	$view->{menu} = \%menus;
	$vbox->pack_start($menubar,FALSE,FALSE,0);

	$vbox->show_all();
	return $vbox;
}


1;
