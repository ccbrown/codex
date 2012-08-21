//
//  FontAndColorPreferences.h
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"
#import "AddThemeView.h"

@class FontTextField;

@interface FontAndColorPreferences : NSPreferencesModule <NSTableViewDataSource, NSTableViewDelegate, AddThemeViewDelegate> {
	IBOutlet NSPopover* _addThemePopover;
	
	IBOutlet NSTableView* _themesTableView;
	IBOutlet NSButton* _addThemeButton;
	IBOutlet NSButton* _removeThemeButton;

	IBOutlet FontTextField* _fontTextField;
	IBOutlet NSButton* _fontButton;

	IBOutlet NSColorWell* _defaultColorWell;
	IBOutlet NSColorWell* _keywordColorWell;
	IBOutlet NSColorWell* _commentColorWell;
	IBOutlet NSColorWell* _directiveColorWell;
	IBOutlet NSColorWell* _constantColorWell;
	IBOutlet NSColorWell* _quoteColorWell;
	IBOutlet NSColorWell* _functionColorWell;
	IBOutlet NSColorWell* _identifierColorWell;

	IBOutlet NSColorWell* _backgroundColorWell;
	IBOutlet NSColorWell* _selectionColorWell;
	IBOutlet NSColorWell* _cursorColorWell;	
}

- (IBAction)buttonAction:(NSButton*)sender;

- (IBAction)colorWellAction:(NSColorWell*)sender;

@end
