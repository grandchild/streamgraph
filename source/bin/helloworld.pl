#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;
use Gnome2::Canvas;
use Time::HiRes qw(gettimeofday);

use lib "./lib/";

use StreamGraph::View;
use StreamGraph::View::ItemFactory;
use StreamGraph::Model::NodeFactory;
use StreamGraph::CodeGen;
use StreamGraph::Util::PropertyWindow;

my $window   = Gtk2::Window->new('toplevel');
$window->signal_connect('button-release-event',\&_window_handler);
$window->signal_connect('leave-notify-event',\&_window_handler);
my $uimanager;
my $menu_edit;
my $menu_filter;
my $menu = create_menu();
my $scroller = Gtk2::ScrolledWindow->new();
my $view     = StreamGraph::View->new(aa=>1);
$view->set(connection_arrows=>'one-way');
my $factory  = StreamGraph::View::ItemFactory->new(view=>$view);
my $nodeFactory = StreamGraph::Model::NodeFactory->new();

$view->set_scroll_region(-50,-90,100,100);
$scroller->add($view);
$window->signal_connect('destroy'=>sub { _closeapp($view); });
$window->set_default_size(400,400);
$window->set_type_hint('dialog');
$window->add($menu);
$menu->add($scroller);

my $item1 = _text_item($factory,
	$nodeFactory->createNode(
		type=>"StreamGraph::Model::Filter",
		name=>"IntGenerator",
		globalVariables=>"int x;",
		initCode=>"x = 0;",
		workCode=>"push(x++);",
		timesPush=>1,
		outputType=>"int",
		outputCount=>1
		));
$view->add_item($item1);
my $item2 = _text_item($factory,
	$nodeFactory->createNode(
		type=>"StreamGraph::Model::Filter",
		name=>"Printer",
		workCode=>"println(pop());",
		inputType=>"int",
		inputCount=>1,
		timesPop=>1
		));
$view->add_item($item2);

$view->connect($item1,$item2);

print $item1->{data};
print "\n----------------\n\n";
print StreamGraph::CodeGen::generateCode($item1, "");

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
	my ($factory, $data) = @_;
	my $item = $factory->create_item(border=>'StreamGraph::View::Border::RoundedRect',
					content=>'StreamGraph::View::Content::EllipsisText',
					text=>$data->name,
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
	# print $item . "Event, type: $event_type  coords: @coords\n";

	if ($event_type eq 'button-press' && $event->button == 1) {
		my @coords_prime = $item->w2i(@coords); # cursor position.
		$item->{x_prime} = $coords_prime[0];
		$item->{y_prime} = $coords_prime[1];
	} elsif ($event_type eq 'motion-notify') {
		unless (defined $item->{y_prime}) {return;}
		my @coords_prime = $item->w2i(@coords); # cursor position.
		$item->{x_move} = $coords_prime[0];
		$item->{y_move} = $coords_prime[1];
		my ($item_x, $item_y) = $item->get(qw(x y));
		$item->set(x=>($item_x + ($item->{x_move}- $item->{x_prime}) ));
		$item->set(y=>($item_y + ($item->{y_move}- $item->{y_prime}) ));
		$item->{x_prime} = $item->{x_move};
		$item->{y_prime} = $item->{y_move};
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
			$menu_edit->popup(undef, undef, undef, undef, $event->button, 0);
		}
}

sub addFilter {
  my $item = _text_item($factory,
	$nodeFactory->createNode(
		type=>"StreamGraph::Model::Filter",
		name=>"Filter",
		workCode=>"println(pop());",
		inputType=>"int",
		inputCount=>1,
		timesPop=>1
		));
  $view->add_item($item);
}

sub addParameter {
	my $item = $factory->create_item(border=>'StreamGraph::View::Border::Rectangle',
					content=>'StreamGraph::View::Content::EllipsisText',
					text=>"Parameter",
					font_desc=>Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
					hotspot_color_gdk=>Gtk2::Gdk::Color->parse('lightgreen'),
					# outline_color_gdk=>Gtk2::Gdk::Color->parse('blue'),
					fill_color_gdk   =>Gtk2::Gdk::Color->parse('white'),
					);

	$item->signal_connect(event=>\&_test_handler);
	$view->add_item($item);
	return $item;
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
		[ "NewF", undef, 'Neuer Filter', undef, undef, \&addFilter ],
		[ "NewP", undef, 'Neuer Parameter', undef, undef, \&addParameter ],
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
