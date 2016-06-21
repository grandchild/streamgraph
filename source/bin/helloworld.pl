#!/usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Gnome2::Canvas;

use lib "./lib/";

use StreamGraph::View;
use StreamGraph::View::ItemFactory;
use StreamGraph::NodeData;
use StreamGraph::CodeGen;

my $window   = Gtk2::Window->new();
my $scroller = Gtk2::ScrolledWindow->new();
my $view     = StreamGraph::View->new(aa=>1);
my $factory  = StreamGraph::View::ItemFactory->new(view=>$view);

$view->set_scroll_region(-50,-90,100,100);
$scroller->add($view);
$window->signal_connect('destroy'=>sub { _closeapp($view); });
$window->set_default_size(400,400);
$window->set_type_hint('dialog');
$window->add($scroller);

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
#    print "item: $item  event: $event\n";
	my $event_type = $event->type;
	my @coords = $event->coords;
	print "Event, type: $event_type  coords: @coords\n";
}


1;
