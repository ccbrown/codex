//
//  GeneralPreferences.h
//  CodeX
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"

@interface GeneralPreferences : NSPreferencesModule {
	BOOL _hasShownAutoSavingAlert;
	
	IBOutlet NSButton* _restoreWindowsButton;
	IBOutlet NSButton* _openNewDocumentButton;
	
	IBOutlet NSButton* _documentShortcutsButton;
	IBOutlet NSButton* _statusBarButton;
	
	IBOutlet NSButton* _autoSavingButton;
	
	IBOutlet NSStepper* _maxRecentDocumentsStepper;
	IBOutlet NSTextField* _maxRecentDocumentsField;
}

- (IBAction)buttonAction:(NSButton*)sender;
- (IBAction)stepperAction:(NSStepper*)sender;

@end
