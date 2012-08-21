//
//  EditingPreferences.h
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"

@interface EditingPreferences : NSPreferencesModule {
	IBOutlet NSPopUpButton* _indentTypeButton;
	IBOutlet NSButton* _lineNumbersButton;
	IBOutlet NSTextField* _tabSpacesTextField;
	IBOutlet NSStepper* _tabSpacesStepper;

	IBOutlet NSButton* _lineWrapButton;
	IBOutlet NSPopUpButton* _encodingButton;
	IBOutlet NSPopUpButton* _lineEndingsButton;
	
	IBOutlet NSButton* _autoIndentNewLinesButton;
	IBOutlet NSButton* _autoIndentCloseBracesButton;
}

- (IBAction)buttonAction:(NSButton*)sender;
- (IBAction)stepperAction:(NSStepper*)sender;

@end
