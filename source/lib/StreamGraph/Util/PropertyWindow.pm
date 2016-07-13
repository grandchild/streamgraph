package StreamGraph::Util::PropertyWindow;

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/;

sub show {
	my ($item,$window) = @_;

	if (defined $item->{dialog}) { return; }
	my $dialog = Gtk2::Dialog->new(
		'Property Window',
		$window,
		[qw/destroy-with-parent/],
	);
	$item->{dialog} = $dialog;

	if ($item->isFilter) {
		show_filter($item,$dialog);
	} elsif ($item->isParameter) {
		show_parameter($item,$dialog);
	} elsif ($item->isComment) {
		show_comment($item,$dialog);
	}
}

sub show_comment {
	my ($item,$dialog) = @_;

	my $itemData = $item->{data};
	my $dbox = $dialog->vbox;

	# PARAMETER NAME ENTRY
	my $CommentStringHbox = Gtk2::HBox->new(FALSE,0);
	$CommentStringHbox->pack_start(Gtk2::Label->new("Comment: "),FALSE,FALSE,0);
	my $commentStringE = Gtk2::Entry->new();
	$commentStringE->set_text($itemData->{name});
	$commentStringE->signal_connect(changed => sub{
		$itemData->{name} = $commentStringE->get_text();
		$item->{border}->{content}->set(text => $commentStringE->get_text());
		$item->update;
	});
	$CommentStringHbox->pack_start($commentStringE,FALSE,FALSE,0);
	$dbox->pack_start($CommentStringHbox,FALSE,FALSE,0);
	$dbox->show_all();
	$dialog->signal_connect('delete-event'=>sub { undef $item->{dialog}; $dialog->destroy(); });
	$dialog->show();
}

sub show_parameter {
	my ($item,$dialog) = @_;

	my $itemData = $item->{data};
	my $dbox = $dialog->vbox;

	# PARAMETER NAME ENTRY
	my $filterNameHbox = Gtk2::HBox->new(FALSE,0);
	$filterNameHbox->pack_start(Gtk2::Label->new("Name: "),FALSE,FALSE,0);
	my $filterNameE = Gtk2::Entry->new();
	$filterNameE->set_text($itemData->{name});
	$filterNameE->signal_connect(changed => sub{
		$itemData->{name} = $filterNameE->get_text();
	});
	$filterNameHbox->pack_start($filterNameE,FALSE,FALSE,0);
	$dbox->pack_start($filterNameHbox,FALSE,FALSE,0);

	# PARAMETER TYPE ENTRY
	my $filterTypeHbox = Gtk2::HBox->new(FALSE,0);
	$filterTypeHbox->pack_start(Gtk2::Label->new("Type: "),FALSE,FALSE,0);
	my $filterTypeE = Gtk2::Entry->new();
	$filterTypeE->set_text($itemData->{outputType});
	$filterTypeE->signal_connect(changed => sub{
		$itemData->{outputType} = $filterTypeE->get_text();
	});
	$filterTypeHbox->pack_start($filterTypeE,FALSE,FALSE,0);
	$dbox->pack_start($filterTypeHbox,FALSE,FALSE,0);

	# PARAMETER VALUE ENTRY
	my $filterValueHbox = Gtk2::HBox->new(FALSE,0);
	$filterValueHbox->pack_start(Gtk2::Label->new("Value: "),FALSE,FALSE,0);
	my $filterValueE = Gtk2::Entry->new();
	$filterValueE->set_text($itemData->{value});
	$filterValueE->signal_connect(changed => sub{
		$itemData->{value} = $filterValueE->get_text();
		$item->{border}->{content}->set(text => $filterValueE->get_text());
		$item->update;
	});
	$filterValueHbox->pack_start($filterValueE,FALSE,FALSE,0);
	$dbox->pack_start($filterValueHbox,FALSE,FALSE,0);

	$dbox->show_all();
	$dialog->signal_connect('delete-event'=>sub { undef $item->{dialog}; $dialog->destroy(); });
	$dialog->show();
}

sub show_filter {
	my ($item,$dialog) = @_;

	my $itemData = $item->{data};
	my $dbox = $dialog->vbox;

	# FILTER NAME ENTRY
	my $filterNameHbox = Gtk2::HBox->new(FALSE,0);
	$filterNameHbox->pack_start(Gtk2::Label->new("Name: "),FALSE,FALSE,0);
	my $filterNameE = Gtk2::Entry->new();
	$filterNameE->set_text($itemData->{name});
	$filterNameE->signal_connect(changed => sub{
		$itemData->{name} = $filterNameE->get_text();
		$item->{border}->{content}->set(text => $filterNameE->get_text());
		$item->update;
	});
	$filterNameHbox->pack_start($filterNameE,FALSE,FALSE,0);
	$dbox->pack_start($filterNameHbox,FALSE,FALSE,0);

	# FILTER FILTER JOIN TABS
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
	$joinCB->append_text('Void');
	if ($itemData->{joinType} eq 'roundrobin') {
		$joinCB->set_active(0);
	} elsif ($itemData->{joinType} eq 'Void') {
		$joinCB->set_active(1);
	} else {
		$joinCB->set_active(0);
	}
	$joinCB->signal_connect(changed => sub{
		if ($joinCB->get_active_text eq 'Round Robin') {
			$itemData->{joinType} = "roundrobin";
		} elsif ($joinCB->get_active_text eq 'Void') {
			$itemData->{joinType} = "void";
		}
	});
	$joinCBhbox->pack_start(Gtk2::Label->new("Type: "),FALSE,FALSE,0);
	$joinCBhbox->pack_start($joinCB,FALSE,FALSE,0);
	$joinTab->pack_start($joinCBhbox,FALSE,FALSE,0);

	# JOIN UNIFY SLICE COUNTS CHECK BOX
	my $joinCheck = Gtk2::CheckButton->new("Unify slice counts");
	$joinCheck->set_active($itemData->{joinRRForAll});
	$joinCheck->signal_connect(toggled => sub { $itemData->{joinRRForAll} = $joinCheck->get_active(); });
	$joinTab->pack_start($joinCheck,FALSE,FALSE,0);

	# FILTER TAB
	my $filterTab = Gtk2::VBox->new(FALSE,0);
	$nb->append_page($filterTab,Gtk2::Label->new("Filter"));

	# FILTER INIT TEXTVIEW
	my $filterGlobVarLabel = Gtk2::Label->new("Globale Variablen");
	$filterGlobVarLabel->set_alignment(0, 0);
	$filterTab->pack_start($filterGlobVarLabel,FALSE,FALSE,0);
	my $filterGlobVarView = Gtk2::TextView->new();
	my $filterGlobVarBuffer = $filterGlobVarView->get_buffer();
	$filterGlobVarBuffer->set_text($itemData->{globalVariables});
	$filterGlobVarBuffer->signal_connect(changed => sub{
		$itemData->{globalVariables} = $filterGlobVarBuffer->get_text(
			$filterGlobVarBuffer->get_start_iter,
			$filterGlobVarBuffer->get_end_iter,
			TRUE
		);
	});
	$filterTab->pack_start($filterGlobVarView,FALSE,FALSE,0);

	$filterTab->pack_start(Gtk2::HSeparator->new(),FALSE,TRUE,10); # SEPARATOR

	# FILTER INIT TEXTVIEW
	my $filterInitLabel = Gtk2::Label->new("Init");
	$filterInitLabel->set_alignment(0, 0);
	$filterTab->pack_start($filterInitLabel,FALSE,FALSE,0);
	my $filterInitView = Gtk2::TextView->new();
	my $filterInitBuffer = $filterInitView->get_buffer();
	$filterInitBuffer->set_text($itemData->{initCode});
	$filterInitBuffer->signal_connect(changed => sub{
		$itemData->{initCode} = $filterInitBuffer->get_text(
			$filterInitBuffer->get_start_iter,
			$filterInitBuffer->get_end_iter,
			TRUE
		);
	});
	$filterTab->pack_start($filterInitView,FALSE,FALSE,0);

	$filterTab->pack_start(Gtk2::HSeparator->new(),FALSE,TRUE,10); # SEPARATOR

	# FILTER PUSH ENTRY
	my $filterPushHbox = Gtk2::HBox->new(FALSE,0);
	$filterPushHbox->pack_start(Gtk2::Label->new("Push: "),FALSE,FALSE,0);
	my $filtePushE = Gtk2::Entry->new();
	$filtePushE->set_text($itemData->{timesPush});
	$filtePushE->signal_connect(changed => sub{	$itemData->{timesPush} = $filtePushE->get_text(); });
	$filterPushHbox->pack_start($filtePushE,FALSE,FALSE,0);
	$filterTab->pack_start($filterPushHbox,FALSE,FALSE,0);

	# FILTER POP ENTRY
	my $filterPopHbox = Gtk2::HBox->new(FALSE,0);
	$filterPopHbox->pack_start(Gtk2::Label->new("Pop: "),FALSE,FALSE,0);
	my $filtePopE = Gtk2::Entry->new();
	$filtePopE->set_text($itemData->{timesPop});
	$filtePopE->signal_connect(changed => sub{	$itemData->{timesPop} = $filtePopE->get_text(); });
	$filterPopHbox->pack_start($filtePopE,FALSE,FALSE,0);
	$filterTab->pack_start($filterPopHbox,FALSE,FALSE,0);

	# FILTER Peek ENTRY
	my $filterPeekHbox = Gtk2::HBox->new(FALSE,0);
	$filterPeekHbox->pack_start(Gtk2::Label->new("Peek: "),FALSE,FALSE,0);
	my $filtePeekE = Gtk2::Entry->new();
	$filtePeekE->set_text($itemData->{timesPeek});
	$filtePeekE->signal_connect(changed => sub{	$itemData->{timesPeek} = $filtePeekE->get_text(); });
	$filterPeekHbox->pack_start($filtePeekE,FALSE,FALSE,0);
	$filterTab->pack_start($filterPeekHbox,FALSE,FALSE,0);

	$filterTab->pack_start(Gtk2::HSeparator->new(),FALSE,TRUE,10); # SEPARATOR

	# FILTER WORK TEXTVIEW
	my $filterWorkLabel = Gtk2::Label->new("Work");
	$filterWorkLabel->set_alignment(0, 0);
	$filterTab->pack_start($filterWorkLabel,FALSE,FALSE,0);
	my $filterWorkView = Gtk2::TextView->new();
	my $filterWorkBuffer = $filterWorkView->get_buffer();
	$filterWorkBuffer->set_text($itemData->{workCode});
	$filterWorkBuffer->signal_connect(changed => sub{
		$itemData->{workCode} = $filterWorkBuffer->get_text(
			$filterWorkBuffer->get_start_iter,
			$filterWorkBuffer->get_end_iter,
			TRUE
		);
	});
	$filterTab->pack_start($filterWorkView,FALSE,FALSE,0);

	$filterTab->pack_start(Gtk2::HSeparator->new(),FALSE,TRUE,10); # SEPARATOR

	# FILTER INPUT ENTRY
	my $filterInhbox = Gtk2::HBox->new(FALSE,0);
	$filterInhbox->pack_start(Gtk2::Label->new("Input: "),FALSE,FALSE,0);
	my $filteInE = Gtk2::Entry->new();
	$filteInE->set_text($itemData->{inputType});
	$filteInE->signal_connect(changed => sub{	$itemData->{inputType} = $filteInE->get_text(); });
	$filterInhbox->pack_start($filteInE,FALSE,FALSE,0);
	$filterTab->pack_start($filterInhbox,FALSE,FALSE,0);

	# FILTER INPUT ENTRY
	my $filterOuthbox = Gtk2::HBox->new(FALSE,0);
	$filterOuthbox->pack_start(Gtk2::Label->new("Output: "),FALSE,FALSE,0);
	my $filteOutE = Gtk2::Entry->new();
	$filteOutE->set_text($itemData->{outputType});
	$filteOutE->signal_connect(changed => sub{	$itemData->{outputType} = $filteOutE->get_text(); });
	$filterOuthbox->pack_start($filteOutE,FALSE,FALSE,0);
	$filterTab->pack_start($filterOuthbox,FALSE,FALSE,0);

	# SPLIT TAB
	my $splitTab = Gtk2::VBox->new(FALSE,0);
	$nb->append_page($splitTab,Gtk2::Label->new("Split"));

	# SPLIT TYPE COMBO BOX
	my $splitCBhbox = Gtk2::HBox->new(FALSE,0);
	my $splitCB = Gtk2::ComboBox->new_text;
	$splitCB->set_title("Type");
	$splitCB->append_text('Round Robin');
	$splitCB->append_text('Duplicate');
	$splitCB->append_text('Void');
	if ($itemData->{splitType} eq 'roundrobin') {
		$splitCB->set_active(0);
	} elsif ($itemData->{splitType} eq 'Duplicate') {
	$splitCB->set_active(1);
	} elsif ($itemData->{splitType} eq 'Void') {
		$splitCB->set_active(2);
	} else {
		$splitCB->set_active(0);
	}
	$splitCB->signal_connect(changed => sub{
		if ($splitCB->get_active_text eq 'Round Robin') {
			$itemData->{splitType} = "roundrobin";
		} elsif ($splitCB->get_active_text eq 'Duplicate') {
			$itemData->{splitType} = "duplicate";
		} elsif ($splitCB->get_active_text eq 'Void') {
			$itemData->{splitType} = "void";
		}
	});
	$splitCBhbox->pack_start(Gtk2::Label->new("Type: "),FALSE,FALSE,0);
	$splitCBhbox->pack_start($splitCB,FALSE,FALSE,0);
	$splitTab->pack_start($splitCBhbox,FALSE,FALSE,0);

	# SPLIT UNIFY SLICE COUNTS CHECK BOX
	my $splitCheck = Gtk2::CheckButton->new("Unify slice counts");
	$splitCheck->set_active($itemData->{splitRRForAll});
	$splitCheck->signal_connect(toggled => sub { $itemData->{splitRRForAll} = $splitCheck->get_active(); });
	$splitTab->pack_start($splitCheck,FALSE,FALSE,0);

	$dbox->add($nb);
	$dbox->show_all();
	$dialog->signal_connect('delete-event'=>sub { undef $item->{dialog}; $dialog->destroy(); });
	$dialog->show();
}

1;
