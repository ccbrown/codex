//
//  EditingWindow.h
//  CodeX
//
//  Created by Christopher Brown on 11/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "TextDocument.h"

@interface EditingWindow : NSWindow <NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate> {
	BOOL _updateWhenKey;
	
	NSMutableArray* _documents;

	IBOutlet NSTextField* _statusTextField;

	IBOutlet NSSplitView* _splitView;

	IBOutlet NSView* _leftView;
	
	IBOutlet NSView* _rightView;
	
	IBOutlet NSTableView* _leftTableView;
}

- (TextDocument*)activeDocument;

- (void)updateViews;

- (void)closeWindow:(id)sender;

- (void)addDocument:(TextDocument*)document;
- (void)addDocument:(TextDocument*)document atIndex:(NSUInteger)index;

- (void)removeDocument:(TextDocument*)document;

- (void)showDocument:(TextDocument*)document;

- (void)reloadPreferences;

- (void)reloadTableRowViewForDocument:(TextDocument*)document;

@property (readonly) NSArray* documents;

@end
