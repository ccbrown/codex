//
//  SyntaxPreferences.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SyntaxPreferences.h"
#import "SyntaxDefinition.h"

@implementation SyntaxPreferences

- (BOOL)isResizable {
	return NO;
}

- (void)willBeDisplayed {
	[_definitionsTableView reloadData];
	
	[_definitionsTableView registerForDraggedTypes:[NSArray arrayWithObject:@"SyntaxDefinitionPreferencesTableDrag"]];
	
	if ([[Preferences sharedPreferences].syntaxDefinitions count] >= 1) {
		[_definitionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[_removeDefinitionButton setEnabled:YES];
	} else {
		[_removeDefinitionButton setEnabled:NO];
	}

	[_processorPopUpButton removeAllItems];
	for (NSString* processor in [SyntaxDefinition processorClassNames]) {
		[_processorPopUpButton addItemWithTitle:processor];
	}
	
	[self updateRightSide];
}

- (IBAction)buttonAction:(NSButton*)sender {
	if (sender == _addDefinitionButton) {
		[_addDefinitionPopover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMinYEdge];
	} else if (sender == _removeDefinitionButton) {
		Preferences* prefs = [Preferences sharedPreferences];
		NSInteger definitionIndex = [_definitionsTableView selectedRow];
		[_definitionsTableView beginUpdates];
		[prefs.syntaxDefinitions removeObjectAtIndex:definitionIndex];
		[_definitionsTableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:definitionIndex] withAnimation:NSTableViewAnimationEffectFade];
		[_definitionsTableView endUpdates];
		if (definitionIndex < [prefs.syntaxDefinitions count]) {
			[_definitionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:definitionIndex] byExtendingSelection:NO];
		} else if ([prefs.syntaxDefinitions count] > 0) {
			[_definitionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[prefs.syntaxDefinitions count] - 1] byExtendingSelection:NO];
		}
		[_removeDefinitionButton setEnabled:([prefs.syntaxDefinitions count] > 0)];
		
		[self updateRightSide];
		[prefs sendUpdates];
	} else if (sender == _processorPopUpButton) {
		NSInteger index = [_processorPopUpButton indexOfSelectedItem];
		
		NSArray* classNames = [SyntaxDefinition processorClassNames];

		if (index >= 0 && index < [classNames count]) {
			SyntaxDefinition* definition = [[Preferences sharedPreferences].syntaxDefinitions objectAtIndex:[_definitionsTableView selectedRow]];
			definition.processorClassName = [classNames objectAtIndex:index];		
		}

		[[Preferences sharedPreferences] sendUpdates];
	}
}

- (void)textDidChange:(NSNotification *)notification {
	NSTextView* textView = [notification object];
	NSMutableCharacterSet* characterSet = [NSMutableCharacterSet new];
	[characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[characterSet addCharactersInString:@","];
	NSMutableArray* array = [NSMutableArray arrayWithArray:[[textView string] componentsSeparatedByCharactersInSet:characterSet]];
	[array removeObject:@""];
	SyntaxDefinition* definition = [[Preferences sharedPreferences].syntaxDefinitions objectAtIndex:[_definitionsTableView selectedRow]];
	if (textView == _extensionsTextView) {
		definition.extensions = array;
	} else if (textView == _keywordsTextView) {
		definition.keywords = array;
	}
	[characterSet release];
	
	[[Preferences sharedPreferences] sendUpdates];
}

- (BOOL)shouldEnableDuplicateButton {
	return ([_definitionsTableView selectedRow] >= 0);
}

- (void)duplicateDefinition {
	if ([_definitionsTableView selectedRow] < 0) {
		return;
	}
	
	Preferences* prefs = [Preferences sharedPreferences];
	
	SyntaxDefinition* definitionCopy = [[prefs.syntaxDefinitions objectAtIndex:[_definitionsTableView selectedRow]] copy];
	
	[prefs.syntaxDefinitions addObject:definitionCopy];
		
	[_definitionsTableView reloadData];
	[_definitionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[prefs.syntaxDefinitions indexOfObject:definitionCopy]] byExtendingSelection:NO];

	[definitionCopy release];

	[_removeDefinitionButton setEnabled:YES];
	
	[_addDefinitionPopover close];
}

- (void)createDefinitionFromTemplate:(NSString *)name {
	Preferences* prefs = [Preferences sharedPreferences];

	SyntaxDefinition* definition = [[SyntaxDefinition alloc] initFromTemplate:name];
	
	[prefs.syntaxDefinitions addObject:definition];

	[_definitionsTableView reloadData];
	[_definitionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[prefs.syntaxDefinitions indexOfObject:definition]] byExtendingSelection:NO];
	
	[definition release];
	
	[_removeDefinitionButton setEnabled:YES];
	
	[_addDefinitionPopover close];

	[prefs sendUpdates];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[Preferences sharedPreferences].syntaxDefinitions count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [(SyntaxDefinition*)[[Preferences sharedPreferences].syntaxDefinitions objectAtIndex:row] name];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	NSString* string = object;
	
	NSRange firstNonwhitespace = [string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
	
	if (firstNonwhitespace.location != NSNotFound) {
		((SyntaxDefinition*)[[[Preferences sharedPreferences] syntaxDefinitions] objectAtIndex:rowIndex]).name = string;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if ([_definitionsTableView selectedRow] < 0) {
		return;
	}
	
	[self updateRightSide];
}

- (void)updateRightSide {
	if ([_definitionsTableView selectedRow] < 0) {
		[_definitionView setHidden:YES];
		[_noDefinitionView setHidden:NO];
		return;
	}
	
	SyntaxDefinition* definition = [[Preferences sharedPreferences].syntaxDefinitions objectAtIndex:[_definitionsTableView selectedRow]];

	[_definitionView setHidden:NO];
	[_noDefinitionView setHidden:YES];

	NSUInteger index = [[SyntaxDefinition processorClassNames] indexOfObject:definition.processorClassName];
	
	if (index != NSNotFound) {
		[_processorPopUpButton selectItemAtIndex:index];
	}
	
	[_extensionsTextView setString:[definition.extensions componentsJoinedByString:@", "]];
	[_keywordsTextView setString:[definition.keywords componentsJoinedByString:@", "]];
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
	[pboard declareTypes:[NSArray arrayWithObject:@"SyntaxDefinitionPreferencesTableDrag"] owner:self];
	[pboard setData:data forType:@"SyntaxDefinitionPreferencesTableDrag"];
	
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
	
	if ([[pboard types] containsObject:@"SyntaxDefinitionPreferencesTableDrag"]) {
		NSData* data = [pboard dataForType:@"SyntaxDefinitionPreferencesTableDrag"];
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
		SyntaxDefinition* definition = [[prefs.syntaxDefinitions objectAtIndex:index] retain];
		[prefs.syntaxDefinitions removeObjectAtIndex:index];
		[prefs.syntaxDefinitions insertObject:definition atIndex:dest];
		[definition release];
		[tableView moveRowAtIndex:index toIndex:dest];
		[tableView endUpdates];

		[prefs sendUpdates];

		return YES;
	}
	
	return NO;
}

@end
