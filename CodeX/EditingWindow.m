//
//  EditingWindow.m
//  CodeX
//
//  Created by Christopher Brown on 11/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EditingWindow.h"
#import "EditingWindowController.h"
#import "TextDocument.h"
#import "FileTableCellView.h"
#import "CodeXAppDelegate.h"
#import "Preferences.h"
#import "FontAndColorPreferences.h"

@implementation EditingWindow 

@synthesize documents = _documents;

- (void)awakeFromNib {	
	_documents = [[NSMutableArray alloc] initWithCapacity:1];
	
	TextDocument* document = [[self windowController] document];
	if (document) {
		[self showDocument:document];
	}
	
	[_leftTableView setRowHeight:39.0];
	
	[_leftTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"EditingWindowTableDrag", NSFilenamesPboardType, nil]];

	[[_statusTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];

	[_splitView setAutosaveName:[[NSProcessInfo processInfo] globallyUniqueString]];
	
	_updateWhenKey = YES;
}

- (void)makeKeyWindow {
	[super makeKeyWindow];
	if (_updateWhenKey) {
		[self updateViews];
		_updateWhenKey = NO;
	}
}

- (TextDocument*)activeDocument {
	TextDocument* controllerDocument = [[self windowController] document];
	if (controllerDocument && [[_rightView subviews] containsObject:controllerDocument.documentView]) {
		return controllerDocument;
	}
	
	for (TextDocument* document in _documents) {
		if ([[_rightView subviews] containsObject:document.documentView]) {
			return document;
		}
	}
	
	return nil;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem {
	if ([menuItem action] == @selector(aBESelectLineEndings:)) {
		// line ending items
		NSIndexSet* selected = [_leftTableView selectedRowIndexes];

		BOOL first = YES;
		BOOL* firstPtr = &first;
		
		NSString* ending = ([menuItem tag] == 1 ? @"\n" : @"\r\n");
		
		[selected enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			TextDocument* document = (TextDocument*)[_documents objectAtIndex:idx];
			
			NSCellStateValue thisState = ([document.lineEnding compare:ending] == NSOrderedSame ? NSOnState : NSOffState);
			NSCellStateValue consState = (*firstPtr ? thisState : [menuItem state]);
			
			if (thisState == consState) {
				[menuItem setState:thisState];
			} else {
				[menuItem setState:NSMixedState];
				*stop = YES;
			}

			*firstPtr = NO;
		}];
	} else if ([menuItem menu] == kCodeXAppDelegate.encodingMenu) {
		// encoding items
		NSIndexSet* selected = [_leftTableView selectedRowIndexes];
		
		BOOL first = YES;
		BOOL* firstPtr = &first;
		
		[selected enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			TextDocument* document = (TextDocument*)[_documents objectAtIndex:idx];
			
			NSCellStateValue thisState = (document.encoding == (NSStringEncoding)menuItem.tag ? NSOnState : NSOffState);
			NSCellStateValue consState = (*firstPtr ? thisState : [menuItem state]);
			
			if (thisState == consState) {
				[menuItem setState:thisState];
			} else {
				[menuItem setState:NSMixedState];
				*stop = YES;
			}
			
			*firstPtr = NO;
		}];
	} else if ([menuItem action] == @selector(aBEToggleLineWrap:)) {
		if ([self activeDocument].wrapsLines) {
			[menuItem setTitle:@"Don't Line Wrap Text"];
		} else {
			[menuItem setTitle:@"Line Wrap Text"];
		}
	}
	
	return [super validateMenuItem:menuItem];
}

- (void)updateViews {	
	NSIndexSet* selected = [_leftTableView selectedRowIndexes];

	if ([selected count] < 1) {
		// this should never happen, but just in case, don't try to update anything else
		return;
	}

	TextDocument* document = [self activeDocument];

	if (document && !document.error) {
		NSString* lineEndingsString;
		if ([document.lineEnding compare:@"\n"] == NSOrderedSame) {
			lineEndingsString = @"Line Endings: LF";
		} else if ([document.lineEnding compare:@"\r\n"] == NSOrderedSame) {
			lineEndingsString = @"Line Endings: CRLF";
		} else {
			lineEndingsString = @"";
		}

		[_statusTextField setStringValue:[NSString stringWithFormat:@"Length: %lu \u00B7 Selection: %ld/%ld \u00B7 Encoding: %@ \u00B7 %@", [document.textView string].length, [document.textView selectedRange].location, [document.textView selectedRange].length, [NSString localizedNameOfStringEncoding:document.encoding], lineEndingsString]];
	} else {
		[_statusTextField setStringValue:@""];
	}
}

- (void)addDocument:(TextDocument*)document atIndex:(NSUInteger)index {
	if (![_documents containsObject:document]) {
		[_documents insertObject:document atIndex:index];
		[document addWindowController:[self windowController]];
		[_leftTableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectNone];
		[_leftTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [_documents count] - index)] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
	}
}

- (void)addDocument:(TextDocument*)document {
	[self addDocument:document atIndex:[_documents count]];
}

- (void)removeDocument:(TextDocument*)document {
	NSUInteger index = [_documents indexOfObject:document];
	[_documents removeObject:document];
	if ([document.documentView isDescendantOf:_rightView]) {
		[document.documentView removeFromSuperview];
	}
	[document removeWindowController:[self windowController]];
	[_leftTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectNone];
	[_leftTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [_documents count] - index)] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];
	// TODO: Figure out why the default delegate won't encode documents?
	[(NSKeyedArchiver*)coder setDelegate:nil];
	[coder encodeObject:_documents forKey:@"textDocuments"];
	[coder encodeInt:[_documents indexOfObject:[[self windowController] document]] forKey:@"activeDocument"];
	[coder encodeObject:[_splitView autosaveName] forKey:@"splitViewAutoSaveName"];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
	[super restoreStateWithCoder:coder];
	NSDictionary* documents = [coder decodeObjectForKey:@"textDocuments"];
	for (TextDocument* document in documents) {
		if (!document.error) {
			[self addDocument:document];
		}
	}
	if ([_documents count] == 0) {
		[self closeWindow:self];
	}
	[_leftTableView reloadData];
	if ([_documents count] > [coder decodeIntForKey:@"activeDocument"]) {
		[_leftTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[coder decodeIntForKey:@"activeDocument"]] byExtendingSelection:NO];
	} else if ([_documents count] > 0) {
		[_leftTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	NSString* svasn = [coder decodeObjectForKey:@"splitViewAutoSaveName"];
	if (svasn) {
		[_splitView setAutosaveName:svasn];
	}

	_updateWhenKey = YES;
}

- (void)showDocument:(TextDocument*)document {
	[self addDocument:document];

	[_rightView setSubviews:[NSArray arrayWithObject:document.documentView]];
	[document.documentView setFrame:(NSRect){0.0, 0.0, _rightView.frame.size}];
	[[self windowController] setDocument:document];
	if (!document.error) {
		[self makeFirstResponder:document.textView];
	} else {
		[self makeFirstResponder:_leftTableView];
	}
	
	if (![_leftTableView isRowSelected:[_documents indexOfObject:document]]) {
		[_leftTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[_documents indexOfObject:document]] byExtendingSelection:NO];
	}
	
	[self updateViews];
	[document updateView];
}

- (void)closeDocuments:(NSArray*)documents {
	for (TextDocument* document in documents) {		
		NSUInteger n = [_documents indexOfObject:document];

		BOOL wasActive = ([self activeDocument] == document);
		
		[self removeDocument:document];

		if (wasActive && [_documents count] >= 1) {
			if (n < [_documents count]) {
				[self showDocument:[_documents objectAtIndex:n]];
			} else if (n > 0) {
				[self showDocument:[_documents objectAtIndex:n - 1]];
			} else {
				[self showDocument:[_documents objectAtIndex:0]];
			}
		}

		[document close];
	}
}

- (void)document:(NSDocument*)document shouldClose:(BOOL)shouldClose contextInfo:(void*)contextInfo {
	if (shouldClose) {
		TextDocument* nextDocument = nil;
		NSUInteger n = [_documents indexOfObject:document];
		if (contextInfo) {
			// close specific documents
			NSIndexSet* indices = contextInfo;
			NSUInteger nextIndex = [indices indexGreaterThanIndex:n];
			if (nextIndex != NSNotFound) {
				nextDocument = [_documents objectAtIndex:nextIndex];
			} else {
				[self closeDocuments:[_documents objectsAtIndexes:indices]];
				[indices release];
			}
		} else {
			// close all documents
			if (n + 1 < [_documents count]) {
				nextDocument = [_documents objectAtIndex:n + 1];
			} else {
				[self closeDocuments:[NSArray arrayWithArray:_documents]];
				[self close];
			}
		}
		if (nextDocument) {
			[self showDocument:nextDocument];
			[nextDocument canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo:contextInfo];
		}
	} else {
		[kCodeXAppDelegate documentCloseCanceled];
	}
}

- (void)performClose:(id)sender {
	if ([_documents count] == [_leftTableView numberOfSelectedRows]) {
		[self closeWindow:sender];
		return;
	} else if ([_leftTableView numberOfSelectedRows] >= 1) {
		NSIndexSet* indices = [[_leftTableView selectedRowIndexes] copy];
		TextDocument* document = [_documents objectAtIndex:[indices indexGreaterThanOrEqualToIndex:0]];
		[self showDocument:document];
		[document canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo:indices];
	}
}

- (void)closeWindow:(id)sender {
	if ([_documents count] >= 1) {
		TextDocument* document = [_documents objectAtIndex:0];
		[self showDocument:document];
		[document canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo:NULL];
	} else {
		[self close];
	}
}

- (BOOL)textView:(NSTextView *)textView doKeyDownByEvent:(NSEvent *)event {
	// control + tab (+ shift)
	if ([event keyCode] == 48 && ([NSEvent modifierFlags] & NSControlKeyMask) && !([NSEvent modifierFlags] & (NSAlternateKeyMask | NSCommandKeyMask))) {
		NSUInteger currentIndex = [_documents indexOfObject:[self activeDocument]];
		NSUInteger nextIndex = currentIndex;
		if ([NSEvent modifierFlags] & NSShiftKeyMask) {
			// backward
			if (currentIndex > 0) {
				nextIndex = currentIndex - 1;
			} else if ([_documents count] > 0) {
				nextIndex = [_documents count] - 1;
			}
		} else {
			// forward
			if (currentIndex + 1 < [_documents count]) {
				nextIndex = currentIndex + 1;
			} else {
				nextIndex = 0;
			}
		}
		
		if (nextIndex != currentIndex && nextIndex < [_documents count]) {
			[self showDocument:[_documents objectAtIndex:nextIndex]];
		}
		
		return YES;
	}
	
	return NO;
}

- (void)keyDown:(NSEvent*)event {
	// command + 0-9
	if ([[event charactersIgnoringModifiers] length] == 1 && ([NSEvent modifierFlags] & NSCommandKeyMask) && !([NSEvent modifierFlags] & (NSAlternateKeyMask | NSShiftKeyMask | NSControlKeyMask))) {
		char c = [[event charactersIgnoringModifiers] characterAtIndex:0];

		int index = -1;
		if (c >= '1' && c <= '9') {
			index = c - '1';
		} else if (c == '0') {
			index = 9;
		}

		if (index >= 0 && index < [_documents count]) {
			[self showDocument:[_documents objectAtIndex:index]];
			return;
		}
	}

	[super keyDown:event];
}

- (void)reloadPreferences {
	for (TextDocument* document in _documents) {
		[document reloadPreferences];
	}

	Preferences* prefs = [Preferences sharedPreferences];
	
	NSSize contentSize = ((NSView*)self.contentView).bounds.size;
	if (prefs.showStatusBar) {
		[self setContentBorderThickness:24.0 forEdge:NSMinYEdge];
		[_splitView setFrame:NSMakeRect(0.0, 24.0, contentSize.width, contentSize.height - 24.0)];
		[_statusTextField setFrame:NSMakeRect(0.0, 2.0, contentSize.width, 17.0)];
		[_statusTextField setHidden:NO];
	} else {
		[self setContentBorderThickness:0.0 forEdge:NSMinYEdge];
		[_splitView setFrame:NSMakeRect(0.0, 0.0, contentSize.width, contentSize.height)];
		[_statusTextField setHidden:YES];
	}
	
	NSIndexSet* indexes = [[_leftTableView selectedRowIndexes] retain];
	[_leftTableView reloadData];
	[_leftTableView selectRowIndexes:indexes byExtendingSelection:NO];
	[indexes release];
}

- (void)aBESelectEncoding:(NSMenuItem*)sender {
	NSStringEncoding encoding = sender.tag;

	NSIndexSet* indexes = [_leftTableView selectedRowIndexes];
	
	NSMutableArray* unconverted = [NSMutableArray arrayWithCapacity:1];
	
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		if (![(TextDocument*)[_documents objectAtIndex:idx] convertToEncoding:encoding]) {
			[unconverted addObject:[_documents objectAtIndex:idx]];
		}
	}];
	
	if ([unconverted count] > 0) {
		NSMutableString* documentsString = [NSMutableString stringWithString:@""];
		NSAlert* alert = [NSAlert new];
		bool first = YES;
		for (TextDocument* document in unconverted) {
			if (first) {
				[documentsString appendString: document.displayName];
			} else {
				[documentsString appendFormat:@", %@", document.displayName];
			}
			first = NO;
		}
		[alert setMessageText:@"The following documents could not be losslessly converted to the selected encoding and were unchanged."];
		[alert setInformativeText:documentsString];
		[alert beginSheetModalForWindow:self modalDelegate:nil didEndSelector:nil contextInfo:NULL];
		[alert release];
	}

	[self updateViews];
}

- (void)reloadWithEncodingAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(NSDictionary*)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
		[self reloadDocumentsWithIndexes:[contextInfo objectForKey:@"indexes"] encoding:[[contextInfo objectForKey:@"encoding"] unsignedIntValue]];
	}
	[contextInfo release];
}

- (void)aBEReloadWithEncoding:(NSMenuItem*)sender {
	NSStringEncoding encoding = sender.tag;
	
	NSIndexSet* indexes = [_leftTableView selectedRowIndexes];
	
	NSMutableArray* unsaved = [NSMutableArray arrayWithCapacity:1];

	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		if ([(TextDocument*)[_documents objectAtIndex:idx] isDocumentEdited]) {
			[unsaved addObject:[_documents objectAtIndex:idx]];
		}
	}];
	
	if ([unsaved count] > 0) {
		NSMutableString* documentsString = [NSMutableString stringWithString:@""];
		NSAlert* alert = [NSAlert new];
		bool first = YES;
		for (TextDocument* document in unsaved) {
			if (first) {
				[documentsString appendString: document.displayName];
			} else {
				[documentsString appendFormat:@", %@", document.displayName];
			}
			first = NO;
		}
		[documentsString appendString:@"\n\nYour current changes will be lost."];
		[alert setMessageText:@"The following documents have unsaved changes. Are you sure you want to reload them?"];
		[alert setInformativeText:documentsString];
		[alert addButtonWithTitle:@"Reload"];
		[alert addButtonWithTitle:@"Cancel"];
		NSDictionary* contextInfo = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:encoding], @"encoding", indexes, @"indexes", nil] retain];
		[alert beginSheetModalForWindow:self modalDelegate:self didEndSelector:@selector(reloadWithEncodingAlertDidEnd:returnCode:contextInfo:) contextInfo:contextInfo];
		[alert release];
	} else {
		[self reloadDocumentsWithIndexes:indexes encoding:encoding];
	}	
}

- (void)reloadDocumentsWithIndexes:(NSIndexSet*)indexes encoding:(NSStringEncoding)encoding {
	NSMutableArray* unconverted = [NSMutableArray arrayWithCapacity:1];

	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		if (![(TextDocument*)[_documents objectAtIndex:idx] reloadWithEncoding:encoding]) {
			[unconverted addObject:[_documents objectAtIndex:idx]];
		}
	}];
	
	if ([unconverted count] > 0) {
		NSMutableString* documentsString = [NSMutableString stringWithString:@""];
		NSAlert* alert = [NSAlert new];
		bool first = YES;
		for (TextDocument* document in unconverted) {
			if (first) {
				[documentsString appendString: document.displayName];
			} else {
				[documentsString appendFormat:@", %@", document.displayName];
			}
			first = NO;
		}
		[alert setMessageText:@"The following documents could not be reloaded with the selected encoding."];
		[alert setInformativeText:documentsString];
		[alert beginSheetModalForWindow:self modalDelegate:nil didEndSelector:nil contextInfo:NULL];
		[alert release];
	}

	[self updateViews];
}

- (void)aBEConvertLineEndings:(id)sender {
	NSIndexSet* indexes = [_leftTableView selectedRowIndexes];
	
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[(TextDocument*)[_documents objectAtIndex:idx] convertLineEndings];
	}];
	
	[self updateViews];
}

- (void)aBESelectLineEndings:(id)sender {
	NSIndexSet* indexes = [_leftTableView selectedRowIndexes];
	
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		[(TextDocument*)[_documents objectAtIndex:idx] setLineEnding:([sender tag] == 1 ? @"\n" : @"\r\n")];
	}];

	[self updateViews];
}

- (void)aBEToggleLineWrap:(id)sender {
	[self activeDocument].wrapsLines = ![self activeDocument].wrapsLines;
	
	[[self activeDocument] updateView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_documents count];
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	TextDocument* document = [_documents objectAtIndex:row];
	FileTableCellView* view = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];

	NSImage* image;

	if (![[document fileURL] absoluteString]) {
		image = [[NSWorkspace sharedWorkspace] iconForFileType:nil];
	} else {
		image = [[NSWorkspace sharedWorkspace] iconForFile:[[document fileURL] path]];
	}
	
	if (document.error) {
		[image lockFocus];
		[[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.2] set];
		NSRectFillUsingOperation(NSMakeRect(0.0, 0.0, image.size.width, image.size.height), NSCompositeSourceAtop);
		[image unlockFocus];
	} else if ([document isDocumentEdited]) {
		[image lockFocus];
		[[NSColor colorWithDeviceRed:0.7 green:0.5 blue:0.0 alpha:0.2] set];
		NSRectFillUsingOperation(NSMakeRect(0.0, 0.0, image.size.width, image.size.height), NSCompositeSourceAtop);
		[image unlockFocus];
	}
	
	[view setImage:image];

	[view setText:[document displayName]];
	
	if ([Preferences sharedPreferences].showDocumentShortcuts) {
		if (row < 9) {
			[view setRightText:[NSString stringWithFormat:@"\u2318%d", (int)row + 1]];
		} else if (row == 9) {
			[view setRightText:[NSString stringWithFormat:@"\u2318%d", 0]];
		} else {
			[view setRightText:@""];
		}
	} else {
		[view setRightText:@""];
	}
	 
	return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if ([_leftTableView numberOfSelectedRows] == 1) {
		[self showDocument:[_documents objectAtIndex:[_leftTableView selectedRow]]];
	} else {
		[self updateViews];
	}
}

- (NSIndexSet*)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
	if ([proposedSelectionIndexes count] == 0) {
		return [tableView selectedRowIndexes];
	}
	return proposedSelectionIndexes;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:rowIndexes, @"rowIndexes", nil];
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	[pboard declareTypes:[NSArray arrayWithObject:@"EditingWindowTableDrag"] owner:self];
	[pboard setData:data forType:@"EditingWindowTableDrag"];

	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
	if (dropOperation == NSDragOperationCopy) {
		[tableView setDropRow:row dropOperation:NSDragOperationMove];
		return NSDragOperationMove;
	} else if (dropOperation == NSDragOperationMove) {
		return NSDragOperationMove;
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
	if (dropOperation != NSDragOperationMove) {
		return NO;
	}

	NSPasteboard* pboard = [info draggingPasteboard];
	
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		NSArray* files = [pboard propertyListForType:NSFilenamesPboardType];
		for (NSString* name in files) {
			TextDocument* document = [[NSDocumentController sharedDocumentController] makeDocumentWithContentsOfURL:[NSURL fileURLWithPath:name] ofType:@"All Documents" error:nil];
			if (document) {
				[[NSDocumentController sharedDocumentController] noteNewRecentDocument:document];
				[self addDocument:document atIndex:row];
				[self showDocument:document];
			}
		}
		return YES;
	} else if ([[pboard types] containsObject:@"EditingWindowTableDrag"]) {
		NSData* data = [pboard dataForType:@"EditingWindowTableDrag"];
		NSDictionary* dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		NSIndexSet* indexes = [dictionary objectForKey:@"rowIndexes"];
		
		NSMutableArray* rowIndexes  = [NSMutableArray arrayWithCapacity:[indexes count]];
		NSMutableArray* destIndexes = [NSMutableArray arrayWithCapacity:[indexes count]];
		
		EditingWindow* sourceWindow = (EditingWindow*)[(NSView*)[info draggingSource] window];
		
		[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
			NSUInteger r = idx;
			NSUInteger d = row;
			if (d > r && sourceWindow == self) {
				d -= 1;
			}
			for (NSUInteger i = 0; i < [rowIndexes count]; ++i) {
				NSUInteger xr = [[rowIndexes objectAtIndex:i] intValue];
				NSUInteger xd = [[destIndexes objectAtIndex:i] intValue];

				if (xr < r && (xd >= r || sourceWindow != self)) {
					--r;
				} else if (xr >= r && xd < r && sourceWindow == self) {
					++r;
				}
				if (xr <= d && xd > d && sourceWindow == self) {
					--d;
				} else if ((xr > d || sourceWindow != self) && xd <= d) {
					++d;
				}
			}
			[rowIndexes addObject:[NSNumber numberWithInt:r]];
			[destIndexes addObject:[NSNumber numberWithInt:d]];
		}];
		[tableView beginUpdates];
		for (NSUInteger i = 0; i < [rowIndexes count]; ++i) {
			NSUInteger r = [[rowIndexes  objectAtIndex:i] intValue];
			NSUInteger d = [[destIndexes objectAtIndex:i] intValue];
			if (sourceWindow == self) {
				TextDocument* document = [[_documents objectAtIndex:r] retain];
				[_documents removeObjectAtIndex:r];
				[_documents insertObject:document atIndex:d];
				[document release];
				[tableView moveRowAtIndex:r toIndex:d];
			} else {
				TextDocument* document = [[sourceWindow.documents objectAtIndex:r] retain];
				[sourceWindow removeDocument:[sourceWindow.documents objectAtIndex:r]];
				[self addDocument:document atIndex:d];
				[document release];
				[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:d] byExtendingSelection:(i > 0)];
			}
		}
		[tableView endUpdates];
		if (sourceWindow != self) {
			if ([sourceWindow.documents count] > 0) {
				[sourceWindow showDocument:[sourceWindow.documents objectAtIndex:0]];
			}
		}
		return YES;
	}
	
	return NO;
}

- (void)reloadTableRowViewForDocument:(TextDocument*)document {
	[_leftTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:[self.documents indexOfObject:document]] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
}

- (void)changeFont:(id)sender {
	[[FontAndColorPreferences sharedInstance] changeFont:sender];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
	return (subview == _rightView);
}

- (void)dealloc {
	// somehow this window can get dealloc'd while it's still the table view delegate
	_leftTableView.delegate = nil;
	_leftTableView.dataSource = nil;
	
	[_documents release];
	
	[super dealloc];
}

@end
