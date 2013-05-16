//
//  AdvancedFindPanel.m
//  BetterEdit
//
//  Created by Christopher Brown on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AdvancedFindPanel.h"

static AdvancedFindPanel* gAdvancedFindPanelSharedInstance = nil;

@implementation AdvancedFindPanel

+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler {
	completionHandler([AdvancedFindPanel sharedAdvancedFindPanel], nil);
}

+ (AdvancedFindPanel*)sharedAdvancedFindPanel {
	if (!gAdvancedFindPanelSharedInstance) {
		[NSBundle loadNibNamed:@"AdvancedFindPanel" owner:self];
	}
	
	return gAdvancedFindPanelSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
	if (gAdvancedFindPanelSharedInstance) {
		return [[self sharedAdvancedFindPanel] retain];
	}
	
	return [super allocWithZone:zone];
}

- (id)copyWithZone:(NSZone*)zone {
	return self;
}

- (id)autorelease {
	return self;
}

- (id)retain {
	return self;
}

- (oneway void)release {
	// do nothing
}

- (NSUInteger)retainCount {
	return NSUIntegerMax;
}

- (void)awakeFromNib {
	if (!gAdvancedFindPanelSharedInstance) {
		gAdvancedFindPanelSharedInstance = self;		
	}
	
	[self setRestorationClass:[AdvancedFindPanel class]];
	[self setFrameAutosaveName:@"advancedFindPanelFrame"];
	
	self.client = nil;
	_matchRanges = nil;
	_matchesStringHash = 0;
	
	_findHistory = [[NSMutableArray arrayWithCapacity:20] retain];
	_replaceHistory = [[NSMutableArray arrayWithCapacity:20] retain];
	
	_statusField.stringValue = @"";

	[self restoreUserInterfaceState];
}

- (id<AdvancedTextFinderClient>)client {
	return _client;
}

- (void)setClient:(id<AdvancedTextFinderClient>)client {
	if (_client != client) {
		[_client release];
		_client = [client retain];
	}
	[self validateUserInterfaceItems];
}

- (void)advancedFindInputAction:(id)sender {
	if (sender == _ignoreCaseButton || sender == _wrapAroundButton || sender == _typePopUpButton) {
		[self invalidateMatchRanges];
	}
}

- (void)controlTextDidChange:(NSNotification *)notification {
	if ([[[notification userInfo] objectForKey:@"NSFieldEditor"] isDescendantOf:_findComboBox]) {
		[self invalidateMatchRanges];
	}
}

- (void)validateUserInterfaceItems {
	if (self.client) {
		[_nextButton           setEnabled:[self.client validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)_nextButton]];
		[_previousButton       setEnabled:[self.client validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)_previousButton]];
		[_replaceButton        setEnabled:[self.client validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)_replaceButton]];
		[_replaceAndFindButton setEnabled:[self.client validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)_replaceAndFindButton]];
		[_replaceAllButton     setEnabled:[self.client validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)_replaceAllButton]];
	} else {
		[_nextButton           setEnabled:NO];
		[_previousButton       setEnabled:NO];
		[_replaceButton        setEnabled:NO];
		[_replaceAndFindButton setEnabled:NO];
		[_replaceAllButton     setEnabled:NO];
	}
}

- (void)performAdvancedFindPanelAction:(id)sender {
	[self performAction:[sender tag]];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
	if ([item action] == @selector(performAdvancedFindPanelAction:) && self.client) {
		return [self.client validateUserInterfaceItem:item];
	} else {
		return [super validateUserInterfaceItem:item];
	}
}

- (void)invalidateMatchRanges {
	[_matchRanges release];
	_matchRanges = nil;
	
	if (self.client) {
		[self.client hideFindMatches];
	}
}

- (NSArray*)matchRanges {
	if (!self.client) {
		[_matchRanges release];
		_matchRanges = nil;
		return nil;
	}
	
	if (_matchRanges && _matchesStringHash == [[self.client string] hash]) {
		return _matchRanges;
	}
	
	[_matchRanges release];
	_matchRanges = nil;
	
	NSString* string = [self.client string];
	if ([_typePopUpButton selectedItem].tag == 1) {
		NSRange searchRange = NSMakeRange(0, [string length]);
		NSMutableArray* matchRanges = [NSMutableArray arrayWithCapacity:20];
		NSRange matchRange = NSMakeRange(NSNotFound, 0);
		while (searchRange.length > 0) {
			matchRange = [string rangeOfString:[_findComboBox stringValue] options:(([_ignoreCaseButton state] == NSOnState ? NSCaseInsensitiveSearch : 0) | NSLiteralSearch) range:searchRange];
			if (matchRange.location == NSNotFound) {
				break;
			}
			[matchRanges addObject:[NSValue valueWithRange:matchRange]];
			searchRange.location = matchRange.location + matchRange.length;
			searchRange.length   = [string length] - searchRange.location;
		}
		_matchRanges = [matchRanges retain];
		_matchesStringHash = [[self.client string] hash];
	} else if ([_typePopUpButton selectedItem].tag == 2) {
		// regex
		NSError* error = nil;
		NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:[_findComboBox stringValue] options:(([_ignoreCaseButton state] == NSOnState ? NSRegularExpressionCaseInsensitive : 0) | NSRegularExpressionAnchorsMatchLines) error:&error];
		if (!regex) {
			// invalid regex
			return nil;
		}
		NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
		NSMutableArray* matchRanges = [NSMutableArray arrayWithCapacity:[matches count]];
		for (NSTextCheckingResult* match in matches) {
			NSRange range = match.range;
			if (range.length > 0) {
				[matchRanges addObject:[NSValue valueWithRange:range]];
			}
		}
		_matchRanges = [matchRanges retain];
		_matchesStringHash = [[self.client string] hash];
	}
	
	return _matchRanges;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox {
	if (comboBox == _findComboBox) {
		return [_findHistory count];
	} else if (comboBox == _replaceComboBox) {
		return [_replaceHistory count];
	}
	
	return 0;
}

- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index {
	if (comboBox == _findComboBox) {
		return [_findHistory objectAtIndex:index];
	} else if (comboBox == _replaceComboBox) {
		return [_replaceHistory objectAtIndex:index];
	}
	
	return nil;
}

- (void)addToFindHistory:(NSString*)string {
	if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 || ([_findHistory count] > 0 && [[_findHistory objectAtIndex:0] isEqual:string])) {
		return;
	}
	[_findHistory insertObject:string atIndex:0];
	while ([_findHistory count] > 20) {
		[_findHistory removeObjectAtIndex:20];
	}
}

- (void)addToReplaceHistory:(NSString*)string {
	if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0 || ([_replaceHistory count] > 0 && [[_replaceHistory objectAtIndex:0] isEqual:string])) {
		return;
	}
	[_replaceHistory insertObject:string atIndex:0];
	while ([_replaceHistory count] > 20) {
		[_replaceHistory removeObjectAtIndex:20];
	}
}

- (void)performAction:(NSTextFinderAction)action {
	_statusField.stringValue = @"";
	
	if (action == NSTextFinderActionShowFindInterface) {
		[self makeKeyAndOrderFront:nil];
		[_findComboBox becomeFirstResponder];
		[_findComboBox selectText:self];
		return;
	}
	
	if (!self.client) {
		return;
	}
	
	if (action == NSTextFinderActionReplaceAll) {
		[self addToFindHistory:[_findComboBox stringValue]];
		[self addToReplaceHistory:[_replaceComboBox stringValue]];
		
		NSArray* matchRanges = self.matchRanges;
		
		if ([matchRanges count] < 1) {
			_statusField.stringValue = @"Not found";
			NSBeep();
			return;
		}
		
		if ([_typePopUpButton selectedItem].tag == 1) {
			NSMutableArray* replacements = [NSMutableArray arrayWithCapacity:[matchRanges count]];
			for (NSUInteger i = 0; i < [matchRanges count]; ++i) {
				[replacements addObject:[_replaceComboBox stringValue]];
			}
			if ([self.client shouldChangeTextInRanges:matchRanges replacementStrings:replacements]) {
				NSInteger offset = 0;
				for (NSValue* value in matchRanges) {
					NSRange range = [value rangeValue];
					range.location += offset;
					[self.client replaceCharactersInRange:range withString:[_replaceComboBox stringValue]];
					offset += [[_replaceComboBox stringValue] length] - range.length;
				}
				[self.client didChangeText];
			}
		} else if ([_typePopUpButton selectedItem].tag == 2) {
			NSError* error = nil;
			NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:[_findComboBox stringValue] options:(([_ignoreCaseButton state] == NSOnState ? NSRegularExpressionCaseInsensitive : 0) | NSRegularExpressionAnchorsMatchLines) error:&error];
			if (!regex) {
				return;
			}
			NSRange stringRange = NSMakeRange(0, [[self.client string] length]);
			NSString* newString = [regex stringByReplacingMatchesInString:[self.client string] options:(NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds) range:stringRange withTemplate:[_replaceComboBox stringValue]];
			if ([self.client shouldChangeTextInRanges:[NSArray arrayWithObject:[NSValue valueWithRange:stringRange]] replacementStrings:[NSArray arrayWithObject:newString]]) {
				[self.client replaceCharactersInRange:stringRange withString:newString];
				[self.client didChangeText];
			}
		}
		
		return;
	}
	
	if (action == NSTextFinderActionReplace || action == NSTextFinderActionReplaceAndFind) {
		[self addToFindHistory:[_findComboBox stringValue]];
		[self addToReplaceHistory:[_replaceComboBox stringValue]];
		
		NSRange selectionRange = [self.client selectedRange];
		
		NSArray* matchRanges = self.matchRanges;
		
		if ([matchRanges containsObject:[NSValue valueWithRange:selectionRange]]) {
			if ([_typePopUpButton selectedItem].tag == 1) {
				if ([self.client shouldChangeTextInRanges:[NSArray arrayWithObject:[NSValue valueWithRange:selectionRange]] replacementStrings:[NSArray arrayWithObject:[_replaceComboBox stringValue]]]) {
					[self.client replaceCharactersInRange:selectionRange withString:[_replaceComboBox stringValue]];
					[self.client didChangeText];
				}
			} else if ([_typePopUpButton selectedItem].tag == 2) {
				NSError* error = nil;
				NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:[_findComboBox stringValue] options:(([_ignoreCaseButton state] == NSOnState ? NSRegularExpressionCaseInsensitive : 0) | NSRegularExpressionAnchorsMatchLines) error:&error];
				if (!regex) {
					return;
				}
				[regex enumerateMatchesInString:[self.client string] options:(NSMatchingWithTransparentBounds | NSMatchingWithoutAnchoringBounds) range:selectionRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
					if (result.range.location == selectionRange.location && result.range.length == selectionRange.length) {
						NSString* replacement = [regex replacementStringForResult:result inString:[self.client string] offset:0 template:[_replaceComboBox stringValue]];
						if ([self.client shouldChangeTextInRanges:[NSArray arrayWithObject:[NSValue valueWithRange:selectionRange]] replacementStrings:[NSArray arrayWithObject:replacement]]) {
							[self.client replaceCharactersInRange:selectionRange withString:replacement];
							[self.client didChangeText];
						}
						*stop = YES;
					}
				}];
			}
		}
		
		if (action == NSTextFinderActionReplaceAndFind) {
			action = NSTextFinderActionNextMatch;
		} else {
			[self.client showFindMatchesForRanges:self.matchRanges];
			return;
		}
	}
	
	if (action == NSTextFinderActionNextMatch || action == NSTextFinderActionPreviousMatch) {
		[self addToFindHistory:[_findComboBox stringValue]];
		
		// next or previous match
		NSArray* matchRanges = self.matchRanges;
		
		if (!matchRanges) {
			if ([_typePopUpButton selectedItem].tag == 2) {
				_statusField.stringValue = @"Invalid regex";
			} else {
				_statusField.stringValue = @"Error";
			}
			NSBeep();
			return;
		}
		
		NSRange matchRange = NSMakeRange(NSNotFound, 0);
		NSRange selectionRange = [self.client selectedRange];
		
		if (action == NSTextFinderActionNextMatch) {
			// next
			for (NSValue* value in matchRanges) {
				NSRange range = [value rangeValue];
				if (range.location >= selectionRange.location + selectionRange.length) {
					matchRange = range;
					break;
				} else if (matchRange.location == NSNotFound && [_wrapAroundButton state] == NSOnState) {
					matchRange = range;
				}
			}
		} else {
			// previous
			for (NSValue* value in [matchRanges reverseObjectEnumerator]) {
				NSRange range = [value rangeValue];
				if (range.location + range.length <= selectionRange.location) {
					matchRange = range;
					break;
				} else if (matchRange.location == NSNotFound && [_wrapAroundButton state] == NSOnState) {
					matchRange = range;
				}
			}
		}
		
		[self.client showFindMatchesForRanges:matchRanges];
		
		if (matchRange.location == NSNotFound) {
			_statusField.stringValue = @"Not found";
			NSBeep();
			return;
		}
		
		[self.client scrollRangeToVisible:matchRange];
		[self.client setSelectedRange:matchRange];
		[self.client showFindIndicatorForRange:matchRange];
		return;
	}
}

- (BOOL)validateAction:(NSTextFinderAction)action {
	return (self.client != nil);
}

- (void)saveUserInterfaceState {
	NSMutableData* data = [[NSMutableData new] autorelease];
	NSKeyedArchiver* coder = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];

	[coder encodeObject:_findHistory forKey:@"findHistory"];
	[coder encodeObject:_replaceHistory forKey:@"replaceHistory"];
	[coder encodeBool:([_ignoreCaseButton state] == NSOnState) forKey:@"ignoreCase"];
	[coder encodeBool:([_wrapAroundButton state] == NSOnState) forKey:@"wrapAround"];
	[coder encodeInteger:[_typePopUpButton selectedTag] forKey:@"searchType"];
	[coder encodeObject:[_findComboBox stringValue] forKey:@"findString"];
	[coder encodeObject:[_replaceComboBox stringValue] forKey:@"replaceString"];
	
	[coder finishEncoding];

	[[NSUserDefaults standardUserDefaults] setObject:data forKey:@"advancedFindPanelUIState"];
}

- (void)restoreUserInterfaceState {
	NSData* data = [[NSUserDefaults standardUserDefaults] dataForKey:@"advancedFindPanelUIState"];
	if (!data) {
		return;
	}

	NSKeyedUnarchiver* coder = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease];

	[_findHistory addObjectsFromArray:[coder decodeObjectForKey:@"findHistory"]];
	[_replaceHistory addObjectsFromArray:[coder decodeObjectForKey:@"replaceHistory"]];
	[_ignoreCaseButton setState:([coder decodeBoolForKey:@"ignoreCase"] ? NSOnState : NSOffState)];
	[_wrapAroundButton setState:([coder decodeBoolForKey:@"wrapAround"] ? NSOnState : NSOffState)];
	[_typePopUpButton selectItemWithTag:[coder decodeIntegerForKey:@"searchType"]];
	[_findComboBox setStringValue:[coder decodeObjectForKey:@"findString"]];	
	[_replaceComboBox setStringValue:[coder decodeObjectForKey:@"replaceString"]];	
}

- (void)close {
	[self saveUserInterfaceState];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[super close];
}

- (void)dealloc {
	self.client = nil;
	[_matchRanges release];
	
	[_findHistory release];
	[_replaceHistory release];
	
	[super dealloc];
}

@end