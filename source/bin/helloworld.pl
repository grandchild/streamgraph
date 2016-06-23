#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;
use Gnome2::Canvas;
use Time::HiRes qw(gettimeofday);

use lib "./lib/";

use StreamGraph::View;
use StreamGraph::View::ItemFactory;
use StreamGraph::NodeData;
use StreamGraph::CodeGen;
use StreamGraph::Util::PropertyWindow;

my $window   = Gtk2::Window->new();
my $uimanager;
my $menu_edit;
my $menu = create_menu();
my $scroller = Gtk2::ScrolledWindow->new();
my $view     = StreamGraph::View->new(aa=>1);
my $factory  = StreamGraph::View::ItemFactory->new(view=>$view);

$view->set_scroll_region(-50,-90,100,100);
$scroller->add($view);
$window->signal_connect('destroy'=>sub { _closeapp($view); });
$window->set_default_size(400,400);
$window->set_type_hint('dialog');
$window->add($menu);
$menu->add($scroller);

my $item1 = _text_item($factory, "IntGenerator",
	StreamGraph::NodeData->new(
		name=>"IntGenerator",
		globalVariables=>"int x;",
		initCode=>"x = 0;",
		workCode=>"push(x++);",
		timesPush=>1,
		outputType=>"int",
		outputCount=>1
		));
$view->add_item($item1);
my $item2 = _text_item($factory, "Printer",
	StreamGraph::NodeData->new(
		name=>"Printer",
		workCode=>"println(pop());",
		inputType=>"int",
		inputCount=>1,
		timesPop=>1
		));
$view->add_item($item1, $item2);

print $item1->{data};
print "\n----------------\n\n";
print StreamGraph::CodeGen::generateCode($item1, "");

$view->layout();
$window->show_all();

Gtk2->main();

exit 0;


sub _closeapp {
	my $view = shift(@_);
	$view->destroy();
	Gtk2->main_quit();
	return 0;
}


sub _text_item {
	my ($factory, $text, $data) = @_;
	my $item = $factory->create_item(border=>'StreamGraph::View::Border::RoundedRect',
					content=>'StreamGraph::View::Content::EllipsisText',
					text=>$text,
					font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
					hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
					# outline_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
					fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'),
					data=>$data);

	print "_text_item, item: $item\n";
	$item->signal_connect(event=>\&_test_handler);
	return $item;
}

sub _test_handler {
	my ($item, $event) = @_;
	# print "item: $item  event: $event\n";
	my $event_type = $event->type;
	my @coords = $event->coords;
	# print "Event, type: $event_type  coords: @coords\n";

	if ($event_type eq 'button-release' && $event->button == 3) {
		$factory->{focus_item} = $item;
		$menu_edit->popup (undef, undef, undef, undef, $event->button, $event->time);
		return;
	} elsif ($event_type eq 'button-release' && $event->button == 1) {
		if (!defined $item->{clickTiem}) { $item->{clickTiem} = int (gettimeofday * 10); return;}
		StreamGraph::Util::PropertyWindow::show($item->{data}) if int (gettimeofday * 10) - $item->{clickTiem} < 5;
		$item->{clickTiem} = int (gettimeofday * 10);
	}
}

sub addFilter {
  my @successors = $view->successors($factory->{focus_item});
  if (scalar @successors > 0) { return; }
  my $item = _text_item($factory, "Printer",
	StreamGraph::NodeData->new(
		name=>"Filter",
		workCode=>"println(pop());",
		inputType=>"int",
		inputCount=>1,
		timesPop=>1
		));
  $view->add_item($item);
  $view->layout();
}

sub delFilter {
  my @predecessors = $view->predecessors($factory->{focus_item});
  if (scalar @predecessors == 0) {
    $view->remove_item($factory->{focus_item});
  } else {
    foreach my $predecessor_item (@predecessors) {
      $view->remove_item($predecessor_item, $factory->{focus_item});
    }
  }
  $view->layout();
}

sub create_menu {
	my $vbox = Gtk2::VBox->new(FALSE,5);
	my @entries = (
		[ "FileMenu",undef,"_Datei"],
	  [ "New", 'gtk-new', undef,  "<control>N", undef, undef ],
		[ "Open", 'gtk-open', undef,  "<control>O", undef, undef ],
		[ "Save", 'gtk-save', undef,  "<control>S", undef, undef ],
		[ "SaveAs", 'gtk-save-as', undef,  "<shift><control>S", undef, undef ],
		[ "Quit", 'gtk-quit', undef,  "<control>Q", undef, undef ],
		[ "Close", 'gtk-close', undef,  "<shift>W", undef, undef ],
		[ "EditMenu",'gtk-edit'],
		[ "NewT", 'gtk-new', undef,  undef, undef, \&addFilter ],
		[ "Delete", 'gtk-delete', undef, undef, undef, \&delFilter ],
		[ "HelpMenu",'gtk-help'],
		[ "Info", 'gtk-info', undef,  undef, undef, undef ],
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
				<menuitem action='NewT'/>
				<menuitem action='Delete'/>
			</menu>
			<menu action='HelpMenu'>
				<menuitem action='Info'/>
			</menu>
		</menubar>
	</ui>"
	);

	my $menubar = $uimanager->get_widget('/MenuBar');
	$menu_edit = $uimanager->get_widget('/MenuBar/EditMenu')->get_submenu;
	$vbox->pack_start($menubar,FALSE,FALSE,0);

	$vbox->show_all();
	return $vbox;
}

1;
