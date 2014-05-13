//
//  SyntaxPreferences.h
//  CodeX
//
//  Created by Christopher Brown on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"
#import "AddSyntaxDefinitionView.h"

@interface SyntaxPreferences : NSPreferencesModule <NSTableViewDataSource, NSTableViewDelegate, AddSyntaxDefinitionViewDelegate> {
	IBOutlet NSPopover* _addDefinitionPopover;

	IBOutlet NSTableView* _definitionsTableView;
	
	IBOutlet NSButton* _addDefinitionButton;
	IBOutlet NSButton* _removeDefinitionButton;
	
	IBOutlet NSView* _noDefinitionView;
	IBOutlet NSView* _definitionView;
	
	IBOutlet NSPopUpButton* _processorPopUpButton;
	
	IBOutlet NSTextView* _extensionsTextView;
	IBOutlet NSTextView* _keywordsTextView;
}

@end
