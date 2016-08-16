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

create_window(shift);

Gtk2->main();

exit 0;

sub create_window {
	my ($file, $isSubgraph) = @_;
	my %main_gui;
	$main_gui{window}   = Gtk2::Window->new($isSubgraph ? 'toplevel': 'toplevel');
	
	$main_gui{scroller} = Gtk2::ScrolledWindow->new();
	$main_gui{scroller}->signal_connect('event',sub {_window_handler(\%main_gui,@_);});
	$main_gui{scroller}->signal_connect('key-press-event' => sub { show_key(\%main_gui,@_); } );
	$main_gui{view} = StreamGraph::View->new(aa=>1);
	$main_gui{view}->set(connection_arrows=>'one-way');
	$main_gui{window}->set_size_request(900,500);
	$main_gui{menus} = create_menu(\%main_gui);
	$main_gui{scroller}->add($main_gui{view});
	if($isSubgraph) {
		$main_gui{window}->signal_connect('delete-event'=>sub { _closewindow($main_gui{view}); });
	} else {
		$main_gui{window}->signal_connect('destroy'=>sub { _closeapp($main_gui{view}); });
	}
	$main_gui{window}->set_type_hint('dialog');
	$main_gui{window}->add($main_gui{menus});
	$main_gui{menus}->add($main_gui{scroller});

	$main_gui{factory} = StreamGraph::View::ItemFactory->new(view=>$main_gui{view});
	$main_gui{nodeFactory} = StreamGraph::Model::NodeFactory->new();
	$main_gui{config} = StreamGraph::Util::Config->new();

	die "Usage: perl bin/helloworld.pl [filename]\n" if !defined $file;
	$main_gui{saveFile} = $file;
	loadFile(\%main_gui);

	# codeGenShow();
	# runShow();

	$main_gui{window}->signal_connect('leave-notify-event',
		sub { if (defined $main_gui{view}->{toggleCon}) {
				$main_gui{view}->{toggleCon}->{predecessor_item}->{hotspots}->{'toggle_right'}->end_connection;
		}	} );

	$main_gui{window}->show_all();
	$main_gui{view}->set_scroll_region(-1000,-1000,1000,1000);
	scroll_to_center(\%main_gui);
}

sub _closewindow {
	my ($view) = @_;
	$view->destroy();
	return 0;
}
sub _closeapp {
	my ($view) = @_;
	$view->destroy();
	Gtk2->main_quit();
	return 0;
}

sub scroll_to_center{
	my ($main_gui) = @_;
	my ($sx1, $sy1, $sx2, $sy2) = $main_gui->{view}->get_scroll_region();
	my ($width,$height) = $main_gui->{window}->get_size();
	my $x = ($sx2 - $sx1 - $width)/2;
	my $y = ($sy2 - $sy1 - $height)/2;
	$main_gui->{view}->scroll_to($x,$y);
}

sub _test_handler {
	my ($main_gui, $item, $event) = @_;
	# print "item: $item  event: $event\n";
	my $event_type = $event->type;
	my @coords = $event->coords;
	# print $item . "Event, type: $event_type  coords: @coords\n";

	if ($event_type eq 'button-press' && $event->button == 1) {
		$item->{x_prime} = $coords[0];
		$item->{y_prime} = $coords[1];
		$main_gui->{view}->deselect;
		$item->select(1);
		unshift (@{$main_gui->{view}->{focusItem}},$item);
	} elsif ($event_type eq 'motion-notify') {
		unless (defined $item->{y_prime}) {return;}
		$item->set(x=>($item->get('x') + ($coords[0] - $item->{x_prime}) ));
		$item->set(y=>($item->get('y') + ($coords[1] - $item->{y_prime}) ));
		$item->{x_prime} = $coords[0];
		$item->{y_prime} = $coords[1];
	}	elsif ($event_type eq 'button-press' && $event->button == 3) {
		$main_gui->{view}->{popup} = 1;
		$item->select(1);
		unshift (@{$main_gui->{view}->{focusItem}},$item);
	} elsif ($event_type eq '2button-press' && $event->button == 1) {
		StreamGraph::Util::PropertyWindow::show($item,$main_gui->{window});
	} elsif ($event_type eq '2button-press' && $event->button == 3) {
		if($item->isSubgraph) {
			loadSubgraph($item);
		}
	}
	if ($event_type eq 'button-release') {
		undef $item->{x_prime};
		undef $item->{y_prime};
	}
}

sub _window_handler {
    my ($main_gui, $win, $event) = @_;
    my $event_type = $event->type;
    my @coords = $event->coords;

		if ($event_type eq 'button-press' && $event->button == 1) {
			if ($#{$main_gui->{view}->{focusItem}}+1 && defined $main_gui->{view}->{focusItem}->[0]->{x_prime}) { return; }
			my @rcoords = $event->root_coords;
			$main_gui->{view}->{x_prime} = $rcoords[0];
			$main_gui->{view}->{y_prime} = $rcoords[1];
			$main_gui->{view}->deselect;
		} elsif ($event_type eq 'button-press' && $event->button == 3) {
			if ($main_gui->{view}->{popup}) {	return;	}
			$main_gui->{view}->{x1_rect} = $coords[0];
			$main_gui->{view}->{y1_rect} = $coords[1];
			$main_gui->{view}->{selectBox} = Gnome2::Canvas::Item->new(
				$main_gui->{view}->root,
				'Gnome2::Canvas::Rect',
				fill_color_gdk    => Gtk2::Gdk::Color->parse('lightgray'),
				outline_color_gdk => Gtk2::Gdk::Color->parse('gray'),
			);
			$main_gui->{view}->{selectBox}->lower_to_bottom;
		} elsif ($event_type eq 'motion-notify') {
			if (defined $main_gui->{view}->{selectBox}) {
				my ($fx,$fy,$tx, $ty) = $main_gui->{view}->get_scroll_region();
				$main_gui->{view}->{selectBox}->set(x1=>$main_gui->{view}->{x1_rect} + $fx);
				$main_gui->{view}->{selectBox}->set(y1=>$main_gui->{view}->{y1_rect} + $fy);
				$main_gui->{view}->{selectBox}->set(x2=>$coords[0] + $fx);
				$main_gui->{view}->{selectBox}->set(y2=>$coords[1] + $fy);
				$main_gui->{view}->deselect();
				for my $it ($main_gui->{view}->{graph}->{graph}->vertices()){
					my ($x1,$x2,$y1,$y2) = $main_gui->{view}->{selectBox}->get('x1','x2','y1','y2');
					($x1,$x2) = $x1 < $x2 ? ($x1,$x2) : ($x2,$x1);
					($y1,$y2) = $y1 < $y2 ? ($y1,$y2) : ($y2,$y1);
					my $inside = 	$it->get('x') > $x1 &&
												$it->get('x') < $x2 &&
												$it->get('y') > $y1 &&
												$it->get('y') < $y2;
					if ( $inside ){
						unshift (@{$main_gui->{view}->{focusItem}},$it);
						$it->select(1);
					}
				}
			}
			unless (defined $main_gui->{view}->{y_prime}) {return;}
			my ($cx, $cy) = $main_gui->{view}->get_scroll_offsets();
			my @rcoords = $event->root_coords;
			$main_gui->{view}->scroll_to($cx + ($main_gui->{view}->{x_prime} - $rcoords[0]) , $cy + ($main_gui->{view}->{y_prime} - $rcoords[1]) );
			$main_gui->{view}->{x_prime} = $rcoords[0];
			$main_gui->{view}->{y_prime} = $rcoords[1];
			$main_gui->{window}->show_all;
		}
		if ($event_type eq 'button-release') {
			undef $main_gui->{view}->{x_prime};
			undef $main_gui->{view}->{y_prime};
		}
		if ($event_type eq 'button-release' && $event->button == 3) {
			if (defined $main_gui->{view}->{selectBox}) {
				my $returnVal = $main_gui->{view}->{selectBox}->get('x1') - $main_gui->{view}->{selectBox}->get('x2');
				$main_gui->{view}->{selectBox}->destroy();
				undef $main_gui->{view}->{selectBox};
				return if $returnVal;
			}
			if ($main_gui->{view}->{popup}) {	$main_gui->{view}->{popup} = 0;	return;	}
			my @coords = $event->coords;
			$main_gui->{view}->{menuCoordX} =  $coords[0];
			$main_gui->{view}->{menuCoordY} =  $coords[1];
			$main_gui->{menu}->{menu_edit}->popup(undef, undef, undef, undef, $event->button, 0);
		}
}

sub graphViz {
	my ($main_gui) = @_;
	my $graphCompat = StreamGraph::GraphCompat->new($main_gui->{view}->{graph});
	StreamGraph::Util::DebugGraph::export_graph($main_gui->{window},$main_gui->{view},$graphCompat,$main_gui->{config}->get('streamgraph_tmp'));
}

sub codeGenShow {
	my ($main_gui) = @_;
	my $graphCompat = StreamGraph::GraphCompat->new($main_gui->{view}->{graph});
	StreamGraph::Util::DebugCode::show_code(
		$main_gui->{window}, $main_gui->{view},
		StreamGraph::CodeGen::generateCode($graphCompat, "", $main_gui->{config})
	);
}

sub runShow {
	my ($main_gui) = @_;
	my $runner = StreamGraph::CodeRunner->new(config=>$main_gui->{config});
	$runner->setStreamitEnv($main_gui->{config});
	$runner->compileAndRun("main.str", sub{ print $runner->runResult(10); });
}

sub addItem {
	my ($main_gui, $node, $placeUnderMenu) = @_;
	my $item;
	if ($node->isDataNode) {
		$item = addDataNode($main_gui,$node);
	} elsif ($node->isParameter) {
		$item = addParameter($main_gui,$node);
	} elsif ($node->isComment) {
		$item = addComment($main_gui,$node);
	} else {
		croak "Unknown node data type " . ref($node) . "\n";
	}
	$item->signal_connect(event=>sub { _test_handler($main_gui,@_); } );
	$main_gui->{view}->add_item($item);
	if ($placeUnderMenu and defined $main_gui->{view}->{menuCoordX} and defined $main_gui->{view}->{menuCoordY}) {
		my ($width, $height) = $main_gui->{window}->get_size();
		my ($fx,$fy,$tx, $ty) = $main_gui->{view}->get_scroll_region();
		$item->set(x=> ($main_gui->{view}->{menuCoordX} + $fx) );
		$item->set(y=> ($main_gui->{view}->{menuCoordY} + $fx) );
	}
	return $item;
}

sub addDataNode {
	my ($main_gui, $node) = @_;
	my $item = $main_gui->{factory}->create_item(border=>'StreamGraph::View::Border::RoundedRect',
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
	my ($main_gui, $node) = @_;
	my $item = $main_gui->{factory}->create_item(border=>'StreamGraph::View::Border::Rectangle',
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
	my ($main_gui, $node) = @_;
	my $item = $main_gui->{factory}->create_item(border=>'StreamGraph::View::Border::Rectangle',
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
	my ($main_gui, $widget, $event, $parameter) =  @_;
	if ($event->keyval eq "65535") {
		while ($#{$main_gui->{view}->{focusItem}}+1) {
			my $it = shift @{$main_gui->{view}->{focusItem}};
			$main_gui->{view}->remove_item($it);
		}
	}
}

sub delConnection {
	my ($main_gui) = @_;
	$main_gui->{view}->remove_connection($main_gui->{view}->{focusConnection});
}

sub addNewFilter {
	my ($main_gui) = @_;
	addItem(
		$main_gui,
		$main_gui->{nodeFactory}->createNode(
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
	my ($main_gui) = @_;
	addItem(
		$main_gui,
		$main_gui->{nodeFactory}->createNode(
			type=>"StreamGraph::Model::Node::Parameter",
			name=>"Parameter",
			outputType=>"int",
		),
		1
	);
}

sub addNewComment {
	my ($main_gui) = @_;
	addItem(
		$main_gui,
		$main_gui->{nodeFactory}->createNode(
			type=>"StreamGraph::Model::Node::Comment",
			name=>"Comment",
			string=>"Foo happens here"
		),
		1
	);
}

sub saveFile {
	my ($main_gui) = @_;
	unless (defined $main_gui->{saveFile}) {return saveAsFile($main_gui);}
	StreamGraph::Util::File::save($main_gui->{saveFile}, $main_gui->{view}->{graph}, $main_gui->{window});
	$main_gui->{window}->set_title("StreamGraphView - " . $main_gui->{saveFile});
}

sub saveAsFile {
	my ($main_gui) = @_;
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
	$main_gui->{saveFile} = $filename;
	saveFile();
}

sub openFile {
	my ($main_gui) = @_;
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
	$main_gui->{saveFile} = $filename;
	loadFile($main_gui);
}

sub loadFile {
	my ($main_gui) = @_;
	my ($wd, $nodes, $connections) = StreamGraph::Util::File::load($main_gui->{saveFile});
	$main_gui->{view}->clear();
	my @items = map { addItem($main_gui,$_) } @{$nodes};
	map {
		my $data = StreamGraph::Model::ConnectionData->new;
		if ($_->{data}) {
			$data = StreamGraph::Model::ConnectionData->new($_->{data});
		}
		$main_gui->{view}->connect(
			getItemWithId(\@items, $_->{from}),
			getItemWithId(\@items, $_->{to}),
			$data
		)
	} @{$connections};
	my ($x, $y, $w, $h) = ($wd->{x}, $wd->{y}, $wd->{w}, $wd->{h});
	$main_gui->{window}->move($x, $y);
	$main_gui->{window}->set_size_request($w, $h);
}

sub loadSubgraph {
	my ($item) = @_;
	create_window($item->{data}->filepath, 1);
}

sub newFile {
	my ($main_gui) = @_;
	$main_gui->{view}->clear();
	undef $main_gui->{saveFile};
}

sub create_menu {
	my ($main_gui) = @_;
	my $vbox = Gtk2::VBox->new(FALSE,5);
	my @entries = (
		[ "FileMenu",undef,"_Datei"],
		[ "New", 'gtk-new', undef,  "<control>N", undef, sub { newFile($main_gui); } ],
		[ "Open", 'gtk-open', undef,  "<control>O", undef, sub { openFile($main_gui); } ],
		[ "Save", 'gtk-save', undef,  "<control>S", undef, sub { saveFile($main_gui); } ],
		[ "SaveAs", 'gtk-save-as', undef,  "<shift><control>S", undef, sub { saveAsFile($main_gui); } ],
		[ "Quit", 'gtk-quit', undef,  "<control>Q", undef, undef ],
		[ "Close", 'gtk-close', undef,  "<shift>W", undef, undef ],
		[ "EditMenu",'gtk-edit'],
		[ "NewF", undef, 'Neuer Filter', undef, undef, sub { addNewFilter($main_gui); } ],
		[ "NewP", undef, 'Neuer Parameter', undef, undef, sub { addNewParameter($main_gui); } ],
		[ "NewC", undef, 'Neuer Kommentar', undef, undef, sub { addNewComment($main_gui); } ],
		[ "RunMenu", undef, "_Run"],
		[ "RunShow", undef, 'Run', "<control>R", undef, sub { runShow($main_gui); } ],
		[ "DebugMenu", undef, "_Debug"],
		[ "GraphViz", undef, 'Show GraphViz', "<control>D", undef, sub { graphViz($main_gui); } ],
		[ "CodeGenShow", undef, 'Show Streamit Code', "<shift><control>D", undef, sub { codeGenShow($main_gui); } ],
		[ "Connection", undef, undef],
		[ "DelC",'gtk-delete', undef, undef, undef, sub { delConnection($main_gui); } ],
	);
	my $uimanager = Gtk2::UIManager->new;
	my $accelgroup = $uimanager->get_accel_group;
	$main_gui->{window}->add_accel_group($accelgroup);
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

	$main_gui->{menu}->{menu_bar} = $uimanager->get_widget('/MenuBar');
	$main_gui->{menu}->{menu_edit} = $uimanager->get_widget('/MenuBar/EditMenu')->get_submenu;
	$main_gui->{view}->{menu}->{connection} = $uimanager->get_widget('/UnVisible/Connection')->get_submenu;
	$vbox->pack_start($main_gui->{menu}->{menu_bar},FALSE,FALSE,0);

	$vbox->show_all();
	return $vbox;
}


1;
