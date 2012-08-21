//
//  GeneralPreferences.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GeneralPreferences.h"

@implementation GeneralPreferences

- (id)init {
	if (self = [super init]) {
		_hasShownAutoSavingAlert = NO;
	}
	
	return self;
}

- (BOOL)isResizable {
	return NO;
}

- (void)willBeDisplayed {
	Preferences* prefs = [Preferences sharedPreferences];
	
	[_restoreWindowsButton setState:(prefs.restoreWindows ? NSOnState : NSOffState)];
	[_openNewDocumentButton setState:(prefs.openNewDocument ? NSOnState : NSOffState)];

	[_documentShortcutsButton setState:(prefs.showDocumentShortcuts ? NSOnState : NSOffState)];
	[_statusBarButton setState:(prefs.showStatusBar ? NSOnState : NSOffState)];

	[_autoSavingButton setState:(prefs.autoSavesInPlace ? NSOnState : NSOffState)];
	
	[_maxRecentDocumentsStepper setIntValue:prefs.maxRecentDocuments];
	[_maxRecentDocumentsField setIntValue:prefs.maxRecentDocuments];
}

- (IBAction)buttonAction:(NSButton*)sender {
	if (sender == _restoreWindowsButton) {
		[Preferences sharedPreferences].restoreWindows = ([sender state] == NSOnState);
	} else if (sender == _openNewDocumentButton) {
		[Preferences sharedPreferences].openNewDocument = ([sender state] == NSOnState);
	} else if (sender == _documentShortcutsButton) {
		[Preferences sharedPreferences].showDocumentShortcuts = ([sender state] == NSOnState);
		[[Preferences sharedPreferences] sendUpdates];
	} else if (sender == _statusBarButton) {
		[Preferences sharedPreferences].showStatusBar = ([sender state] == NSOnState);
		[[Preferences sharedPreferences] sendUpdates];
	} else if (sender == _autoSavingButton) {
		[Preferences sharedPreferences].autoSavesInPlace = ([sender state] == NSOnState);
		
		if (!_hasShownAutoSavingAlert) {
			NSAlert* alert = [NSAlert new];
			[alert setMessageText:@"Restart required"];
			[alert setInformativeText:@"Your changes to auto-saving and versions won't take effect until you restart the application."];
			[alert beginSheetModalForWindow:[_preferencesView window] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
			[alert release];
			
			_hasShownAutoSavingAlert = YES;
		}
	}
}

- (IBAction)stepperAction:(NSStepper *)sender {
	[_maxRecentDocumentsField setIntValue:[sender intValue]];
	
	[Preferences sharedPreferences].maxRecentDocuments = [sender intValue];
}

- (void)controlTextDidChange:(NSNotification*)notification {
	id object = [notification object];
	
	if (object == _maxRecentDocumentsField) {
		NSTextField* field = object;
		int value = [field intValue];
		if (value < 0) {
			value = 0;
		} else if (value > 100) {
			value = 100;
		}
		[field setIntValue:value];
		[_maxRecentDocumentsStepper setIntValue:value];
		
		[Preferences sharedPreferences].maxRecentDocuments = value;
	}
}

@end
