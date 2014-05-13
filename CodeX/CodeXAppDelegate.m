//
//  CodeXAppDelegate.m
//  CodeX
//
//  Created by Christopher Brown on 11/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeXAppDelegate.h"
#import "EditingWindow.h"
#import	"Preferences.h"

CodeXAppDelegate* kCodeXAppDelegate = nil;

@implementation CodeXAppDelegate

@synthesize encodingMenu, reloadWithEncodingMenu, autoSavesInPlace = _autoSavesInPlace;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	kCodeXAppDelegate = self;

	[NSPreferences setDefaultPreferencesClass:[Preferences class]];

	_autoSavesInPlace = [Preferences sharedPreferences].autoSavesInPlace;

	_textDocumentController = [TextDocumentController new];

	_editingWindowControllers = [[NSMutableArray alloc] initWithCapacity:1];

	_isQuitting = NO;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	[_textDocumentController openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] display:YES error:NULL];
	return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	// on launch, this is called between applicationWillFinishLaunching and applicationDidFinishLaunching
	for (NSString* path in filenames) {
		[_textDocumentController openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES error:NULL];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if (!_autoSavesInPlace) {
		[_fileMenu removeItem:[_fileMenu itemWithTitle:@"Duplicate"]];
	}

	[self.encodingMenu removeAllItems];
	[self.reloadWithEncodingMenu removeAllItems];
	
	NSStringEncoding* encodings = (NSStringEncoding*)[NSString availableStringEncodings];
	for (int i = 0; *encodings != 0; ++encodings, ++i) {
		NSMenuItem* item1 = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:*encodings] action:@selector(aBESelectEncoding:) keyEquivalent:@""];
		[item1 setTag:*encodings];
		[self.encodingMenu addItem:item1];
		[item1 release];
		
		NSMenuItem* item2 = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:*encodings] action:@selector(aBEReloadWithEncoding:) keyEquivalent:@""];
		[item2 setTag:*encodings];
		[self.reloadWithEncodingMenu addItem:item2];
		[item2 release];
	}

	if ([Preferences sharedPreferences].openNewDocument && [_editingWindowControllers count] == 0) {
		[self newWindow:self];
	}
	
	// close these if they've been restored
	[[NSColorPanel sharedColorPanel] close];
	[[NSFontPanel sharedFontPanel] close];
}

- (EditingWindow*)restoreWindowWithState:(NSCoder*)coder {
	if (![Preferences sharedPreferences].restoreWindows) {
		return nil;
	}
	
	EditingWindowController* controller = [[EditingWindowController alloc] initWithWindowNibName:@"EditingWindow"];
	[_editingWindowControllers addObject:controller];
	EditingWindow* window = (EditingWindow*)[controller window];
	window.delegate = self;
	
	[window restoreStateWithCoder:coder];
	
	return window;
}

- (void)newWindow:(id)sender {
	EditingWindowController* controller = [[EditingWindowController alloc] initWithWindowNibName:@"EditingWindow"];
	[_editingWindowControllers addObject:controller];
	NSWindow* window = (EditingWindow*)[controller window];
	window.delegate = self;

	[_textDocumentController openUntitledDocumentAndDisplay:YES error:nil];	
}

- (void)windowWillClose:(NSNotification *)notification {
	NSWindow* window = [notification object];
	if ([window isKindOfClass:[EditingWindow class]]) {
		[_editingWindowControllers removeObject:[window windowController]];
		[[window windowController] release];
	}

	if (_isQuitting && [_editingWindowControllers count] == 0) {
		[NSApp replyToApplicationShouldTerminate:YES];
	}
}

- (void)windowDidEndLiveResize:(NSNotification *)notification {
	NSWindow* window = [notification object];
	
	if ([window isKindOfClass:[EditingWindow class]]) {
		[(EditingWindow*)window updateViews];
		[[(EditingWindow*)window activeDocument] updateView];
	}
}

- (void)documentCloseCanceled {
	if (_isQuitting) {
		[NSApp replyToApplicationShouldTerminate:NO];
		_isQuitting = NO;
	}
}

- (void)openDocument:(id)sender {
	[_textDocumentController openDocument:sender];
}

- (void)openTextDocument:(TextDocument*)document {	
	if ([document isInViewingMode]) {
		NSWindowController* controller = [[NSWindowController alloc] initWithWindowNibName:@"VersionsWindow"];
		[document addWindowController:controller];
		[controller setDocument:document];
		NSView* contentView = [[controller window] contentView];
		[contentView addSubview:document.documentView];
		[document.documentView setFrame:contentView.bounds];
		[document updateView];
		[controller release];
		return;
	}

	EditingWindow* window = nil;

	// find an existing controller
	for (NSWindow* w in [NSApp orderedWindows]) {
		if ([w isKindOfClass:[EditingWindow class]] && [w isVisible]) {
			window = (EditingWindow*)w;
			break;
		}
	}

	// if there are no existing controllers, make a new one
	if (!window) {
		EditingWindowController* controller = [[EditingWindowController alloc] initWithWindowNibName:@"EditingWindow"];
		[_editingWindowControllers addObject:controller];
		window = (EditingWindow*)[controller window];
		window.delegate = self;
		[controller release];
	}

	// show the document
	[window showDocument:document];
	[window makeKeyAndOrderFront:self];
}

- (void)documentUpdated:(TextDocument*)document {
	for (NSWindow* w in [NSApp orderedWindows]) {
		if ([w isKindOfClass:[EditingWindow class]]) {
			EditingWindow* window = (EditingWindow*)w;
			if ([[window documents] containsObject:document]) {
				[window reloadTableRowViewForDocument:document];
				[window updateViews];
				break;
			}
		}
	}
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if ([Preferences sharedPreferences].restoreWindows) {
		return NSTerminateNow;
	}

	BOOL quitLater = NO;
	
	for (NSWindow* w in [sender orderedWindows]) {
		if ([w isKindOfClass:[EditingWindow class]]) {
			quitLater = YES;
			_isQuitting = YES;
			EditingWindow* window = (EditingWindow*)w;
			[window closeWindow:self];
		}
	}
	
	// it's possible for _isQuitting to already be NO, in which case we quit now
	if (quitLater && _isQuitting) {
		return NSTerminateLater;
	}

	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[[Preferences sharedPreferences] saveUserDefaults];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)showPreferences:(id)sender {
	[[Preferences sharedPreferences] showPreferencesPanel];
}

- (void)reloadPreferences {
	for (NSWindow* w in [NSApp orderedWindows]) {
		if ([w isKindOfClass:[EditingWindow class]]) {
			EditingWindow* window = (EditingWindow*)w;
			[window reloadPreferences];
		}
	}
}

- (void) dealloc {
	[_textDocumentController release];

	for (EditingWindowController* c in _editingWindowControllers) {
		[c release];
	}
	
	[_editingWindowControllers release];
	
	[super dealloc];
}

@end
