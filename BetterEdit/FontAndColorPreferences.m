//
//  FontAndColorPreferences.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FontAndColorPreferences.h"
#import "FontTextField.h"
#import "EditingTextView.h"

@implementation FontAndColorPreferences

- (BOOL)isResizable {
	return NO;
}

- (void)willBeDisplayed {
	[_themesTableView reloadData];
	[_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[[Preferences sharedPreferences].themes indexOfObject:[Preferences sharedPreferences].theme]] byExtendingSelection:NO];
	
	[_fontTextField setFontChangeTarget:self];

	[_themesTableView registerForDraggedTypes:[NSArray arrayWithObject:@"ThemePreferencesTableDrag"]];

	[_removeThemeButton setEnabled:([[Preferences sharedPreferences].themes count] > 1)];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[Preferences sharedPreferences].themes count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [(Theme*)[[Preferences sharedPreferences].themes objectAtIndex:row] name];
}

- (IBAction)buttonAction:(NSButton*)sender {
	if (sender == _addThemeButton) {
		[_addThemePopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
	} else if (sender == _removeThemeButton) {
		Preferences* prefs = [Preferences sharedPreferences];
		if ([prefs.themes count] <= 1) {
			// do nothing
			return;
		} else {
			NSInteger themeIndex = [_themesTableView selectedRow];
			[_themesTableView beginUpdates];
			[prefs.themes removeObjectAtIndex:themeIndex];
			[_themesTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:themeIndex] withAnimation:NSTableViewAnimationEffectFade];
			[_themesTableView endUpdates];
			if (themeIndex < [prefs.themes count]) {
				[_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:themeIndex] byExtendingSelection:NO];
			} else {
				[_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[prefs.themes count] - 1] byExtendingSelection:NO];
			}
			[_removeThemeButton setEnabled:([prefs.themes count] > 1)];
		}
	} else if (sender == _fontButton) {
		[[NSFontPanel sharedFontPanel] setPanelFont:[Preferences sharedPreferences].theme.font isMultiple:NO];
		[[NSFontPanel sharedFontPanel] makeKeyAndOrderFront:nil];
		[[_preferencesView window] makeFirstResponder:_fontTextField];
	}
}

- (void)duplicateTheme {
	Preferences* prefs = [Preferences sharedPreferences];

	Theme* theme = [prefs.theme copy];
	
	[prefs.themes addObject:theme];
	prefs.theme = theme;
		
	[_themesTableView reloadData];
	[_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[prefs.themes indexOfObject:theme]] byExtendingSelection:NO];

	[theme release];

	[_removeThemeButton setEnabled:([prefs.themes count] > 1)];

	[_addThemePopover close];
}

- (void)createThemeFromTemplate:(NSString *)name {
	Preferences* prefs = [Preferences sharedPreferences];
	
	Theme* theme = [[Theme alloc] initFromTemplate:name];
	
	[prefs.themes addObject:theme];
	prefs.theme = theme;
		
	[_themesTableView reloadData];
	[_themesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[prefs.themes indexOfObject:theme]] byExtendingSelection:NO];

	[theme release];

	[_removeThemeButton setEnabled:([prefs.themes count] > 1)];

	[_addThemePopover close];
}

- (IBAction)colorWellAction:(NSColorWell*)sender {
	if (sender == _commentColorWell) {
		[Preferences sharedPreferences].theme.commentColor = sender.color;
	} else if (sender == _defaultColorWell) {
		[Preferences sharedPreferences].theme.defaultColor = sender.color;
	} else if (sender == _quoteColorWell) {
		[Preferences sharedPreferences].theme.quoteColor = sender.color;
	} else if (sender == _keywordColorWell) {
		[Preferences sharedPreferences].theme.keywordColor = sender.color;
	} else if (sender == _directiveColorWell) {
		[Preferences sharedPreferences].theme.directiveColor = sender.color;
	} else if (sender == _constantColorWell) {
		[Preferences sharedPreferences].theme.constantColor = sender.color;
	} else if (sender == _functionColorWell) {
		[Preferences sharedPreferences].theme.functionColor = sender.color;
	} else if (sender == _identifierColorWell) {
		[Preferences sharedPreferences].theme.identifierColor = sender.color;
	} else if (sender == _backgroundColorWell) {
		[Preferences sharedPreferences].theme.backgroundColor = sender.color;
	} else if (sender == _selectionColorWell) {
		[Preferences sharedPreferences].theme.selectionColor = sender.color;
	} else if (sender == _cursorColorWell) {
		[Preferences sharedPreferences].theme.cursorColor = sender.color;
	}

	[[Preferences sharedPreferences] sendUpdates];
}

- (void)changeFont:(id)sender {
	Theme* theme = [Preferences sharedPreferences].theme;

	theme.font = [sender convertFont:theme.font];
	
	_fontTextField.stringValue = [NSString stringWithFormat:@"%@ - %.1f", [theme.font displayName], [theme.font pointSize]];
	_fontTextField.font = [NSFont fontWithDescriptor:[theme.font fontDescriptor] size:12.0];

	[[Preferences sharedPreferences] sendUpdates];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	NSString* string = object;

	NSRange firstNonwhitespace = [string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];

	if (firstNonwhitespace.location != NSNotFound) {
		((Theme*)[[[Preferences sharedPreferences] themes] objectAtIndex:rowIndex]).name = string;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if ([_themesTableView selectedRow] < 0) {
		return;
	}
	
	Theme* theme = [[Preferences sharedPreferences].themes objectAtIndex:[_themesTableView selectedRow]];
	
	[Preferences sharedPreferences].theme = theme;

	_fontTextField.stringValue = [NSString stringWithFormat:@"%@ - %.1f", [theme.font displayName], [theme.font pointSize]];
	_fontTextField.font = [NSFont fontWithDescriptor:[theme.font fontDescriptor] size:12.0];

	[_commentColorWell    setColor:theme.commentColor];
	[_defaultColorWell    setColor:theme.defaultColor];
	[_quoteColorWell      setColor:theme.quoteColor];
	[_keywordColorWell    setColor:theme.keywordColor];
	[_directiveColorWell  setColor:theme.directiveColor];
	[_constantColorWell   setColor:theme.constantColor];
	[_functionColorWell   setColor:theme.functionColor];
	[_identifierColorWell setColor:theme.identifierColor];

	[_backgroundColorWell setColor:theme.backgroundColor];
	[_selectionColorWell  setColor:theme.selectionColor];
	[_cursorColorWell     setColor:theme.cursorColor];
	
	[[Preferences sharedPreferences] sendUpdates];
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
	[pboard declareTypes:[NSArray arrayWithObject:@"ThemePreferencesTableDrag"] owner:self];
	[pboard setData:data forType:@"ThemePreferencesTableDrag"];
	
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
	
	if ([[pboard types] containsObject:@"ThemePreferencesTableDrag"]) {
		NSData* data = [pboard dataForType:@"ThemePreferencesTableDrag"];
		NSDictionary* dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		NSIndexSet* indexes = [dictionary objectForKey:@"rowIndexes"];
		
		// only move one
		
		NSUInteger index = [indexes lastIndex];
		NSUInteger dest  = row;
		
		if (dest > index) {
			dest -= 1;
		}

		Preferences* prefs = [Preferences sharedPreferences];
		
		[tableView beginUpdates];
		Theme* theme = [[prefs.themes objectAtIndex:index] retain];
		[prefs.themes removeObjectAtIndex:index];
		[prefs.themes insertObject:theme atIndex:dest];
		[theme release];
		[tableView moveRowAtIndex:index toIndex:dest];
		[tableView endUpdates];

		return YES;
	}
	
	return NO;
}

@end
