#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;
use Gnome2::Canvas;

use lib '../lib';

use Gtk2::Ex::MindMapView;
use Gtk2::Ex::MindMapView::ItemFactory;

my $window   = Gtk2::Window->new();
my $uimanager;
my $menu_edit;
# $window->signal_connect('motion_notify_event',\&_test_handler2);
my $menu = create_menu();
my $scroller = Gtk2::ScrolledWindow->new();
my $view     = Gtk2::Ex::MindMapView->new(aa=>1);
my $factory  = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

$view->set_scroll_region(-350,-325,350,325);
$view->set(connection_arrows=>'one-way');
$scroller->add($view);
$window->signal_connect('destroy'=>sub { _closeapp($view); });
$window->set_default_size(900,350);
$window->add($menu);
$menu->add($scroller);

my $item0 = _text_item($factory, "Start");
$view->add_item($item0);
my $item1 = _text_item($factory, "Filter");
$view->add_item($item0,$item1);

$view->layout();
$window->show_all();

Gtk2->main();

sub _text_item {
  my ($factory, $text) = @_;
  my $item = $factory->create_item(
    border => 'Gtk2::Ex::MindMapView::Border::RoundedRect',
		content => 'Gtk2::Ex::MindMapView::Content::EllipsisText',
		text => $text,
		font_desc => Gtk2::Pango::FontDescription->from_string("Ariel Italic 8"),
		hotspot_color_gdk => Gtk2::Gdk::Color->parse('lightgreen'),
    # outline_color_gdk => Gtk2::Gdk::Color->parse('blue'),
		fill_color_gdk => Gtk2::Gdk::Color->parse('white')
  );

  print "_text_item, item: $item\n";
  $item->signal_connect(event=>\&_test_handler);
  return $item;
}

sub _test_handler
{
  my ($item, $event) = @_;
  my $event_type = $event->type;
  my @coords = $event->coords;

  print "Event, type: $event_type  coords: @coords\n";

  if ($event_type eq 'button-release' && $item->{coords}->[0] == $coords[0] && $item->{coords}->[1] == $coords[1] ) {
    if ($event->button == 3) {
      $factory->{focus_item} = $item;
      $menu_edit->popup (undef, undef, undef, undef, $event->button, $event->time);
      return;
    }

    my $dialog = Gtk2::Dialog->new(
  		'Edit',
  		undef,
  		[qw/modal destroy-with-parent/],
	  );

    my $dbox = $dialog->vbox;

    my $nb = Gtk2::Notebook->new;
    $nb->set_scrollable (TRUE);
    $nb->popup_enable;

    # JOIN TAB
    my $joinTab = Gtk2::VBox->new(FALSE,0);
    $nb->append_page($joinTab,Gtk2::Label->new("Join"));

    # JOIN TYPE COMBO BOX
    my $joinCBhbox = Gtk2::HBox->new(FALSE,0);
    my $joinCB = Gtk2::ComboBox->new_text;
    $joinCB->set_title("Type");
		$joinCB->append_text('Round Robin');
    $joinCB->append_text('Default');
    $joinCB->set_active(0);
    $joinCBhbox->pack_start(Gtk2::Label->new("Type: "),FALSE,FALSE,0);
    $joinCBhbox->pack_start($joinCB,FALSE,FALSE,0);
    $joinTab->pack_start($joinCBhbox,FALSE,FALSE,0);

    # JOIN UNIFY SLICE COUNTS CHECK BOX
    my $joinCheck = Gtk2::CheckButton->new("Unify slice counts");
    $joinTab->pack_start($joinCheck,FALSE,FALSE,0);

    # FILTER TAB
    my $filterTab = Gtk2::VBox->new(FALSE,0);
    $nb->append_page($filterTab,Gtk2::Label->new("Filter"));

    # FILTER INIT TEXTVIEW
    my $filterInitLabel = Gtk2::Label->new("Init");
    $filterInitLabel->set_alignment(0, 0);
    $filterTab->pack_start($filterInitLabel,FALSE,FALSE,0);
    my $filterInitView = Gtk2::TextView->new();
    $filterTab->pack_start($filterInitView,FALSE,FALSE,0);

    $filterTab->pack_start(Gtk2::HSeparator->new(),FALSE,FALSE,0); # SEPARATOR

    # FILTER WORK TEXTVIEW
    my $filterWorkLabel = Gtk2::Label->new("Work");
    $filterWorkLabel->set_alignment(0, 0);
    $filterTab->pack_start($filterWorkLabel,FALSE,FALSE,0);
    my $filterWorkView = Gtk2::TextView->new();
    $filterTab->pack_start($filterWorkView,FALSE,FALSE,0);

    # FILTER INPUT ENTRY
    my $filterInhbox = Gtk2::HBox->new(FALSE,0);
    $filterInhbox->pack_start(Gtk2::Label->new("Input: "),FALSE,FALSE,0);
    my $filteInE = Gtk2::Entry->new();
    $filterInhbox->pack_start($filteInE,FALSE,FALSE,0);
    $filterTab->pack_start($filterInhbox,FALSE,FALSE,0);

    # FILTER INPUT ENTRY
    my $filterOuthbox = Gtk2::HBox->new(FALSE,0);
    $filterOuthbox->pack_start(Gtk2::Label->new("Output: "),FALSE,FALSE,0);
    my $filteOutE = Gtk2::Entry->new();
    $filterOuthbox->pack_start($filteOutE,FALSE,FALSE,0);
    $filterTab->pack_start($filterOuthbox,FALSE,FALSE,0);

    # FILTER SPLIT
    my $splitTab = Gtk2::VBox->new(FALSE,0);
    $nb->append_page($splitTab,Gtk2::Label->new("Split"));

    my $sentry = Gtk2::Entry->new();
    $splitTab->pack_start($sentry,FALSE,FALSE,0);

    $dbox->add($nb);
    $dbox->show_all();
    $window->signal_connect('delete-event'=>sub { $dialog->destroy(); });
    $dialog->show();
  } elsif ($event_type eq 'button-press') {
    $item->{coords} = \@coords;
  }
}

sub _test_handler2
{
    my ($item, $event) = @_;
    my $event_type = $event->type;
    my @coords = $event->coords;

    print "Event, type: $event_type  coords: @coords WINDOW\n ";
    # $submenu->popup(undef, undef, undef, undef, $event->button, $event->time);
}

sub addFilter {
  my @successors = $view->successors($factory->{focus_item});
  if (scalar @successors > 0) { return; }
  my $item = _text_item($factory, "Filter");
  $view->add_item($factory->{focus_item}, $item);
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

sub _closeapp {
  my $view = shift(@_);
  $view->destroy();
  Gtk2->main_quit();
  return 0;
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
