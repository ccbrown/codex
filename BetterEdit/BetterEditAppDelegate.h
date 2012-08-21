//
//  BetterEditAppDelegate.h
//  BetterEdit
//
//  Created by Christopher Brown on 11/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TextDocument.h"
#import "TextDocumentController.h"
#import "EditingWindowController.h"

@interface NSResponder (BECustomActions)
	- (void)aBEConvertLineEndings:(id)sender;
	- (void)aBESelectLineEndings:(id)sender;
	- (void)aBEToggleComment:(id)sender;
	- (void)aBEShiftLeft:(id)sender;
	- (void)aBEShiftRight:(id)sender;
	- (void)aBESelectEncoding:(id)sender;
	- (void)aBEReloadWithEncoding:(id)sender;
	- (void)aBEToggleLineWrap:(id)sender;
@end

@class EditingWindow;

@interface BetterEditAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
	IBOutlet NSMenu* _fileMenu;
	
	TextDocumentController* _textDocumentController;
	
	NSMutableArray* _editingWindowControllers;
	
	BOOL _isQuitting;
	
	BOOL _autoSavesInPlace;
}

- (void)openTextDocument:(TextDocument*)document;

- (void)documentUpdated:(TextDocument*)document;

- (void)documentCloseCanceled;

- (EditingWindow*)restoreWindowWithState:(NSCoder*)coder;

- (void)reloadPreferences;

@property (assign) IBOutlet NSMenu* encodingMenu;
@property (assign) IBOutlet NSMenu* reloadWithEncodingMenu;

@property (readonly) BOOL autoSavesInPlace;

@end

extern BetterEditAppDelegate* kBetterEditAppDelegate;