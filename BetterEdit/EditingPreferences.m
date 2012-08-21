//
//  EditingPreferences.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EditingPreferences.h"

@implementation EditingPreferences

- (BOOL)isResizable {
	return NO;
}

- (void)willBeDisplayed {
	Preferences* prefs = [Preferences sharedPreferences];

	[_indentTypeButton selectItemAtIndex:(prefs.tabKeyInsertsSpaces ? 1 : 0)];
	
	[_lineNumbersButton setState:(prefs.showLineNumbers ? NSOnState : NSOffState)];
	[_tabSpacesStepper setIntValue:prefs.tabSize];
	[_tabSpacesTextField setIntValue:prefs.tabSize];

	[_autoIndentNewLinesButton setState:(prefs.autoIndentNewLines ? NSOnState : NSOffState)];
	[_autoIndentCloseBracesButton setState:(prefs.autoIndentCloseBraces ? NSOnState : NSOffState)];

	[_lineWrapButton setState:(prefs.wrapLinesByDefault ? NSOnState : NSOffState)];

	[_encodingButton removeAllItems];
	NSStringEncoding* encodings = (NSStringEncoding*)[NSString availableStringEncodings];
	for (int i = 0; *encodings != 0; ++encodings, ++i) {
		[_encodingButton addItemWithTitle:[NSString localizedNameOfStringEncoding:*encodings]];
		if (*encodings == prefs.defaultEncoding) {
			[_encodingButton selectItemAtIndex:i];
		}
	}
	
	if ([prefs.defaultLineEnding compare:@"\n"] == NSOrderedSame) {
		[_lineEndingsButton selectItemAtIndex:0];
	} else if ([prefs.defaultLineEnding compare:@"\r\n"] == NSOrderedSame) {
		[_lineEndingsButton selectItemAtIndex:1];
	}
}

- (IBAction)buttonAction:(NSButton*)sender {
	if (sender == _lineNumbersButton) {
		[Preferences sharedPreferences].showLineNumbers = ([sender state] == NSOnState);
		
		[[Preferences sharedPreferences] sendUpdates];
	} else if (sender == _indentTypeButton) {
		[Preferences sharedPreferences].tabKeyInsertsSpaces = ([[[(NSPopUpButton*)sender selectedItem] title] compare:@"Tabs"] != NSOrderedSame);
	} else if (sender == _autoIndentNewLinesButton) {
		[Preferences sharedPreferences].autoIndentNewLines = ([sender state] == NSOnState);
	} else if (sender == _autoIndentCloseBracesButton) {
		[Preferences sharedPreferences].autoIndentCloseBraces = ([sender state] == NSOnState);
	} else if (sender == _lineWrapButton) {
		[Preferences sharedPreferences].wrapLinesByDefault = ([sender state] == NSOnState);
	} else if (sender == _encodingButton) {
		NSStringEncoding* encodings = (NSStringEncoding*)[NSString availableStringEncodings];
		[Preferences sharedPreferences].defaultEncoding = encodings[[(NSPopUpButton*)sender indexOfSelectedItem]];
	} else if (sender == _lineEndingsButton) {
		NSInteger index = [(NSPopUpButton*)sender indexOfSelectedItem];
		if (index == 0) {
			[Preferences sharedPreferences].defaultLineEnding = @"\n";
		} else if (index == 1) {
			[Preferences sharedPreferences].defaultLineEnding = @"\r\n";
		}
	}
}

- (IBAction)stepperAction:(NSStepper *)sender {
	[_tabSpacesTextField setIntValue:[sender intValue]];
	
	[Preferences sharedPreferences].tabSize = [sender intValue];
	
	[[Preferences sharedPreferences] sendUpdates];
}

- (void)controlTextDidChange:(NSNotification*)notification {
	id object = [notification object];
	
	if (object == _tabSpacesTextField) {
		NSTextField* field = object;
		int value = [field intValue];
		if (value < 1) {
			value = 1;
		} else if (value > 100) {
			value = 100;
		}
		[field setIntValue:value];
		[_tabSpacesStepper setIntValue:value];

		[Preferences sharedPreferences].tabSize = value;
	}

	[[Preferences sharedPreferences] sendUpdates];
}

@end
