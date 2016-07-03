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
use StreamGraph::Util;
use StreamGraph::Util::PropertyWindow;
use StreamGraph::Util::Config;
use StreamGraph::Util::File;


my $window   = Gtk2::Window->new('toplevel');
$window->signal_connect('button-release-event',\&_window_handler);
$window->signal_connect('leave-notify-event',\&_window_handler);
my $uimanager;
my $menu_edit;
my $menu_filter;
my $menu = create_menu();
my $scroller = Gtk2::ScrolledWindow->new();
my $view     = StreamGraph::View->new(aa=>1);
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

print StreamGraph::CodeGen::generateCode($view->{graph}, "");

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
		my @coords_prime = $item->w2i(@coords); # cursor position.
		$item->{x_prime} = $coords_prime[0];
		$item->{y_prime} = $coords_prime[1];
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
	} elsif ($event_type eq 'button-release' && $event->button == 1) {
		undef $item->{x_prime};
		undef $item->{y_prime};
		if (!defined $item->{clickTime}) { $item->{clickTime} = int (gettimeofday * 10); return;}
		StreamGraph::Util::PropertyWindow::show($item,$window) if int (gettimeofday * 10) - $item->{clickTime} < 5;
		$item->{clickTime} = int (gettimeofday * 10);
	} elsif ($event_type eq 'enter-notify') {
		if (defined $item->{view}->{tooglePress}) {
			my $titem = $item->{view}->{tooglePress};
			if ($item->{view}->{tooglePress} ne $item && int (gettimeofday * 100) == $titem->{connectTime}) {
				$item->{view}->connect($titem, $item);
			}
			undef $item->{view}->{tooglePress};
		}
	}
}

sub _window_handler {
    my ($win, $event) = @_;
    my $event_type = $event->type;
    my @coords = $event->coords;
		if ($event_type eq 'leave-notify') {
			if (defined $view->{toogleCon}) {
				$view->{toogleCon}->disconnect();
				$view->{toogleCon}->destroy();
				undef $view->{toogleCon};
			}
			return;
		}
		if ($view->{popup}) {
			$view->{popup} = 0;
			return;
		}
		if ($event->button == 3) {
			my @coords = $event->coords;
			$view->{menuCoordX} =  $coords[0];
			$view->{menuCoordY} =  $coords[1];
			$menu_edit->popup(undef, undef, undef, undef, $event->button, 0);
		}
}


sub addItem {
	my ($node) = @_;
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
	if (defined $view->{menuCoordX} and defined $view->{menuCoordY}) {
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
					font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
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
					# font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
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
					font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
					hotspot_color_gdk=>Gtk2::Gdk::Color->parse(''),
					outline_color_gdk=>Gtk2::Gdk::Color->parse('#dfdfdf'),
					fill_color_gdk   =>Gtk2::Gdk::Color->parse('#eee'),
					data=>$node);
	return $item;
}

sub delFilter {
	$view->remove_item($view->{focusItem});
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
		)
	);
}

sub addNewParameter {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Parameter",
			name=>"Parameter",
			outputType=>"int",
		)
	);
}

sub addNewComment {
	addItem(
		$nodeFactory->createNode(
			type=>"StreamGraph::Model::Comment",
			name=>"Comment",
			string=>"Foo happens here"
		)
	);
}

sub saveFile {
	StreamGraph::Util::File::save("helloworld.sigraph", $view->{graph});
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
		[ "SaveAs", 'gtk-save-as', undef,  "<shift><control>S", undef, undef ],
		[ "Quit", 'gtk-quit', undef,  "<control>Q", undef, undef ],
		[ "Close", 'gtk-close', undef,  "<shift>W", undef, undef ],
		[ "EditMenu",'gtk-edit'],
		[ "NewF", undef, 'Neuer Filter', undef, undef, \&addNewFilter ],
		[ "NewP", undef, 'Neuer Parameter', undef, undef, \&addNewParameter ],
		[ "NewC", undef, 'Neuer Kommentar', undef, undef, \&addNewComment ],
		[ "FilterMenu", undef, "_Filter"],
		[ "DelF",'gtk-delete', undef, undef, undef, \&delFilter ],
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
		</menubar>
	</ui>"
	);

	my $menubar = $uimanager->get_widget('/MenuBar');
	$menu_edit = $uimanager->get_widget('/MenuBar/EditMenu')->get_submenu;
	$menu_filter = $uimanager->get_widget('/MenuBar/FilterMenu')->get_submenu;
	$vbox->pack_start($menubar,FALSE,FALSE,0);

	$vbox->show_all();
	return $vbox;
}


1;
