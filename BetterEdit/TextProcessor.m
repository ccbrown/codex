//
//  TextProcessor.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TextDocument.h"
#import "TextProcessor.h"
#import "Preferences.h"
#import "SyntaxDefinition.h"

@implementation TextProcessor

@synthesize keywords = _keywords, singleLineCommentPrefix = _singleLineCommentPrefix, resumePoints = _resumePoints;

- (id)init {
	if (self = [super init]) {		
		self.keywords = nil;
		self.singleLineCommentPrefix = @"//";
		self.resumePoints = [NSMutableArray arrayWithCapacity:10];
	}
	
	return self;
}

+ (TextProcessor*)defaultProcessor {
	return [[TextProcessor new] autorelease];
}

+ (TextProcessor*)processorForExtension:(NSString*)extension {
	for (SyntaxDefinition* definition in [Preferences sharedPreferences].syntaxDefinitions) {
		if ([definition.extensions containsObject:extension]) {
			TextProcessor* processor = [[[NSBundle mainBundle] classNamed:definition.processorClassName] new];
			processor.keywords = definition.keywords;
			return [processor autorelease];
		}
	}
	
	return [TextProcessor defaultProcessor];
}

- (BOOL)isSimilarTo:(TextProcessor*)processor {
	if (processor.keywords != self.keywords && ![processor.keywords isEqualToArray:self.keywords]) {
		return NO;
	}
	if ([processor.singleLineCommentPrefix compare:self.singleLineCommentPrefix] != NSOrderedSame) {
		return NO;
	}
	if ([self class] != [processor class]) {
		return NO;
	}
	return YES;
}

- (NSUInteger)quoteLength:(NSString*)string range:(NSRange)range {
	if (range.length < 1) {
		return 0;
	}
		
	unichar quote = [string characterAtIndex:range.location];
	
	if (quote != '"' && quote != '\'') {
		return 0;
	}
		
	bool escape = false;
	
	NSUInteger i;
	for (i = 1; i < range.length; ++i) {
		unichar c = [string characterAtIndex:range.location + i];
		if (!escape) {
			if (c == quote) {
				return i + 1;
			} else if (c == '\n') {
				return i;
			}
		}
		
		if (c == '\\') {
			escape = !escape;
		} else {
			escape = false;
		}
	}
	
	return i;
}

- (NSUInteger)whiteSpaceLength:(NSString*)string {
	NSRange firstNonwhitespace = [string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
	return (firstNonwhitespace.location == NSNotFound ? [string length] : firstNonwhitespace.location);
}

- (void)addPrefix:(NSString*)prefix toSelectedLinesInTextView:(NSTextView*)textView {
	NSRange selectedRange = [textView selectedRange];

	NSString* string = [textView string];
	
	NSRange lineRange = [string lineRangeForRange:selectedRange];
	
	// trim off the last newline
	BOOL trimmedNewline = NO;
	if (lineRange.length > 0 && [string characterAtIndex:lineRange.location + lineRange.length - 1] == '\n') {
		trimmedNewline = YES;
		lineRange = NSMakeRange(lineRange.location, lineRange.length - 1);
	}
	
	NSString* lines = [string substringWithRange:lineRange];

	NSUInteger newlineCount = 0;

	for (NSUInteger i = 0; i < lineRange.length; ++i) {
		if ([lines characterAtIndex:i] == '\n') {
			++newlineCount;
		}
	}
	
	NSString* replacement = [NSString stringWithFormat:@"%@%@", prefix, [lines stringByReplacingOccurrencesOfString:@"\n" withString:[NSString stringWithFormat:@"\n%@", prefix]]];
	
	if ([textView shouldChangeTextInRange:lineRange replacementString:replacement]) {
		[textView replaceCharactersInRange:lineRange withString:replacement];
		[textView didChangeText];
		
		[textView setSelectedRange:NSMakeRange(lineRange.location, trimmedNewline ? [replacement length] + 1 : [replacement length])];
	}	
}

- (BOOL)removePrefix:(NSString*)prefix fromSelectedLinesInTextView:(NSTextView*)textView {
	NSRange selectedRange = [textView selectedRange];
	
	NSString* string = [textView string];
	
	NSRange lineRange = [string lineRangeForRange:selectedRange];

	// trim off the last newline
	BOOL trimmedNewline = NO;
	if (lineRange.length > 0 && [string characterAtIndex:lineRange.location + lineRange.length - 1] == '\n') {
		trimmedNewline = YES;
		lineRange = NSMakeRange(lineRange.location, lineRange.length - 1);
	}

	NSString* lines = [string substringWithRange:lineRange];

	NSRange firstOccurrence = [lines rangeOfString:prefix];
	
	NSString* replacement = [lines stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"\n%@", prefix] withString:@"\n"];
	if (firstOccurrence.location == 0) {
		replacement = [replacement stringByReplacingCharactersInRange:NSMakeRange(0, [prefix length]) withString:@""];
	}
	
	if ([lines compare:replacement] == NSOrderedSame) {
		return NO;
	}

	if ([textView shouldChangeTextInRange:lineRange replacementString:replacement]) {
		[textView replaceCharactersInRange:lineRange withString:replacement];
		[textView didChangeText];
	}

	[textView setSelectedRange:NSMakeRange(lineRange.location, trimmedNewline ? [replacement length] + 1 : [replacement length])];

	return YES;
}

- (void)syntaxHighlightTextStorage:(NSTextStorage*)textStorage startingAt:(NSUInteger)position {
	Theme* theme = [Preferences sharedPreferences].theme;

	NSString* string = [textStorage string];

	NSUInteger length = [string length] - position;

	while (length > 0 && length < 0x80000000) {
		unichar c1 = [string characterAtIndex:position];

		if (![self addResumePoint:position]) {
			return;
		}
		
		if (c1 == '"') {
			// quote

			NSUInteger quoteLength = [self quoteLength:string range:NSMakeRange(position, length)];
			
			[self colorText:(c1 == '"' ? theme.quoteColor : theme.constantColor) atRange:NSMakeRange(position, quoteLength) textStorage:textStorage];
			
			position += quoteLength;
			length -= quoteLength;
		} else {
			++position;
			--length;
		}
	}
}

- (BOOL)document:(TextDocument *)document textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
	if (selector == @selector(insertNewline:)) {
		// new line
		if (![Preferences sharedPreferences].autoIndentNewLines) {
			return NO;
		}

		NSString* string = [textView string];

		NSRange selectedRange = [textView selectedRange];
		
		NSRange firstLineRange = [string lineRangeForRange:NSMakeRange(selectedRange.location, 0)];

		NSString* firstLine = [string substringWithRange:firstLineRange];
		NSUInteger whitespaceLength = [self whiteSpaceLength:firstLine];
		
		NSString* following = [string substringFromIndex:selectedRange.location + selectedRange.length];
		NSUInteger followingWhitespaceLength = [self whiteSpaceLength:following];

		[[document undoManager] beginUndoGrouping];
		
		NSRange changeRange = NSMakeRange(selectedRange.location + selectedRange.length, followingWhitespaceLength);
		if ([textView shouldChangeTextInRange:changeRange replacementString:@""]) {
			[textView replaceCharactersInRange:changeRange withString:@""];
			[textView didChangeText];
		}

		NSRange bracketRange = [firstLine rangeOfString:@"{"];
		if (bracketRange.location != NSNotFound && firstLineRange.location + bracketRange.location >= selectedRange.location) {
			bracketRange.location = NSNotFound;
		}

		if (bracketRange.location == NSNotFound || (followingWhitespaceLength < [following length] && [following characterAtIndex:followingWhitespaceLength] == '}')) {
			[textView insertText:[NSString stringWithFormat:@"%@%@",   document.lineEnding, [firstLine substringWithRange:NSMakeRange(0, whitespaceLength)]] replacementRange:selectedRange];
		} else {
			[textView insertText:[NSString stringWithFormat:@"%@%@%@", document.lineEnding, [firstLine substringWithRange:NSMakeRange(0, whitespaceLength)], [Preferences sharedPreferences].tabString] replacementRange:selectedRange];
		}

		[[document undoManager] endUndoGrouping];

		return YES;
	} else if (selector == @selector(toggleComment:)) {
		// toggle comment
		NSString* string = [textView string];

		NSRange selectedRange = [textView selectedRange];

		BOOL comment = NO;

		NSUInteger index = selectedRange.location;
		while (index <= selectedRange.location + selectedRange.length) {
			NSRange lineRange = [string lineRangeForRange:NSMakeRange(index, 0)];
			if (selectedRange.length > 0 && lineRange.location >= selectedRange.location + selectedRange.length) {
				break;
			}
			if (lineRange.length < self.singleLineCommentPrefix.length) {
				comment = YES;
				break;
			}
			NSString* commentPrefix = [string substringWithRange:NSMakeRange(lineRange.location, self.singleLineCommentPrefix.length)];
			if ([commentPrefix compare:self.singleLineCommentPrefix] != NSOrderedSame) {
				comment = YES;
				break;
			}
			index += lineRange.length;
		}
		
		if (comment) {
			// comment
			[self addPrefix:self.singleLineCommentPrefix toSelectedLinesInTextView:textView];
		} else {
			// uncomment
			[self removePrefix:self.singleLineCommentPrefix fromSelectedLinesInTextView:textView];
		}

		return YES;
	} else if (selector == @selector(shiftLeft:)) {		
		// shift left
		if (![self removePrefix:[Preferences sharedPreferences].tabString fromSelectedLinesInTextView:textView]) {
			if (![self removePrefix:@"\t" fromSelectedLinesInTextView:textView]) {
				[self removePrefix:@" " fromSelectedLinesInTextView:textView];
			}
		}

		return YES;
	} else if (selector == @selector(shiftRight:)) {
		// shift right
		[self addPrefix:[Preferences sharedPreferences].tabString toSelectedLinesInTextView:textView];
		
		return YES;
	}

	return NO;
}

- (BOOL)document:(TextDocument *)document textView:(NSTextView *)textView doKeyDownByEvent:(NSEvent *)event {
	if ([event keyCode] == 48 && !([NSEvent modifierFlags] & (NSControlKeyMask | NSCommandKeyMask | NSAlternateKeyMask))) {
		// tab
		if ([event modifierFlags] & NSShiftKeyMask) {
			// shift left
			if (![self removePrefix:[Preferences sharedPreferences].tabString fromSelectedLinesInTextView:textView]) {
				if (![self removePrefix:@"\t" fromSelectedLinesInTextView:textView]) {
					[self removePrefix:@" " fromSelectedLinesInTextView:textView];
				}
			}
		} else {
			NSRange selectedRange = [textView selectedRange];
			if (selectedRange.length == 0) {
				// insert indent
				[textView insertText:[Preferences sharedPreferences].tabString];
			} else {
				// shift right
				[self addPrefix:[Preferences sharedPreferences].tabString toSelectedLinesInTextView:textView];
			}
		}
		
		return YES;
	} else if ([[event characters] compare:@"}"] == NSOrderedSame) {
		// closing bracket
		if (![Preferences sharedPreferences].autoIndentCloseBraces) {
			return NO;
		}
		
		NSRange selectedRange = [textView selectedRange];

		NSString* string = [textView string];
		
		NSRange lineRange = [string lineRangeForRange:NSMakeRange(selectedRange.location, 0)];		
		NSString* line = [string substringWithRange:lineRange];
		NSRange lineIndentRange = NSMakeRange(lineRange.location, [self whiteSpaceLength:line]);

		if (lineIndentRange.location + lineIndentRange.length != selectedRange.location) {
			// other characters before the closing bracket
			return NO;
		}

		int count = 1;
		
		NSInteger match = -1;
		
		for (NSInteger i = selectedRange.location - 1; i >= 0; --i) {
			char c = [string characterAtIndex:i];
			if (c == '{') {
				if (count == 1) {
					match = i;
					break;
				} else {
					--count;
				}
			} else if (c == '}') {
				++count;
			}
		}	
		
		if (match == -1) {
			// no matching bracket
			return NO;
		}

		NSRange matchLineRange = [string lineRangeForRange:NSMakeRange(match, 1)];
		NSString* matchLine = [string substringWithRange:matchLineRange];
		NSRange matchIndentRange = NSMakeRange(matchLineRange.location, [self whiteSpaceLength:matchLine]);

		[[document undoManager] beginUndoGrouping];
		
		[textView insertText:@"}"];
		
		NSString* replacement = [string substringWithRange:matchIndentRange];
		if ([textView shouldChangeTextInRange:lineIndentRange replacementString:replacement]) {
			[textView replaceCharactersInRange:lineIndentRange withString:replacement];
			[textView didChangeText];
		}

		[[document undoManager] endUndoGrouping];

		return YES;
	}
	
	return NO;
}

- (void)document:(TextDocument*)document textView:(NSTextView*)textView didChangeSelection:(NSRange)oldSelection {
	NSRange currentSelection = [textView selectedRange];
	NSString* string = [textView string];
	
	if (oldSelection.length == 0 && currentSelection.length == 0) {
		// bracket matching
		NSInteger index;
		
		if (oldSelection.location == currentSelection.location - 1) {
			index = oldSelection.location;		
		} else if (oldSelection.location == currentSelection.location + 1) {
			index = currentSelection.location;
		} else {
			return;
		}
		
		NSUInteger len = [string length];
		
		if (index >= len) {
			return;
		}
		
		unichar c = [string characterAtIndex:index];
		unichar match;
		int direction = 1;
		if (c == '(') {
			match = ')';
		} else if (c == ')') {
			match = '(';
			direction = -1;
		} else if (c == '{') {
			match = '}';
		} else if (c == '}') {
			match = '{';
			direction = -1;
		} else if (c == '[') {
			match = ']';
		} else if (c == '[') {
			match = ']';
			direction = -1;
		} else {
			return;
		}
		
		int count = 0;
		NSInteger matchIndex = -1;
		
		for (NSInteger i = index; i >= 0 && i < len; i += direction) {
			unichar c2 = [string characterAtIndex:i];
			if (c2 == c) {
				count += 1;
			} else if (c2 == match) {				
				if (count == 1) {
					matchIndex = i;
					break;
				} else {
					count -= 1;
				}
			}
		}
		
		if (matchIndex >= 0) {
			[textView showFindIndicatorForRange:NSMakeRange(matchIndex, 1)];
		}
	}
}

- (void)colorText:(NSColor*)color atRange:(NSRange)range textStorage:(NSTextStorage*)textStorage {
	if (range.location > _highlightNextHighlight) {
		Theme* theme = [Preferences sharedPreferences].theme;
		NSRange r = NSMakeRange(_highlightNextHighlight, range.location - _highlightNextHighlight);
		[textStorage removeAttribute:NSForegroundColorAttributeName range:r];
		[textStorage addAttribute:NSForegroundColorAttributeName value:theme.defaultColor range:r];
	}

	[textStorage addAttribute:NSForegroundColorAttributeName value:color range:range];
	_highlightNextHighlight = range.location + range.length;
}

- (BOOL)addResumePoint:(NSUInteger)position {
	// remove any resume points between _highlightResumeIndex and this...
	while (_highlightResumeIndex + 1 < [_resumePoints count]) {
		NSUInteger val = [[_resumePoints objectAtIndex:_highlightResumeIndex + 1] unsignedIntegerValue];
		if (position > val) {
			[_resumePoints removeObjectAtIndex:_highlightResumeIndex + 1];
		} else if (position == val) {
			// if we find one that matches, we're done
			// ...unless we haven't gone through _highlightGoThrough yet
			if (position < _highlightGoThrough) {
				++_highlightResumeIndex;
				return YES;
			}
			_highlightStopPosition = position;
			return NO;
		} else {
			break;
		}
	}
	
	if (_highlightResumeIndex < [_resumePoints count]) {
		NSUInteger last = [[_resumePoints objectAtIndex:_highlightResumeIndex] unsignedIntegerValue];
		if (position - last < 200) {
			// too soon, don't add another resume point here
			return YES;
		}
	}

	// insert this and increment _highlightResumeIndex
	if (_highlightResumeIndex + 1 >= [_resumePoints count]) {
		[_resumePoints addObject:[NSNumber numberWithUnsignedInteger:position]];
		_highlightResumeIndex = [_resumePoints count] - 1;
	} else {
		[_resumePoints insertObject:[NSNumber numberWithUnsignedInteger:position] atIndex:++_highlightResumeIndex];
	}

	return YES;
}

- (void)resetTextStorage:(NSTextStorage*)textStorage {
	[_resumePoints removeAllObjects];

	_lastHash = [[textStorage string] hash];

	_highlightResumeIndex   = 0;
	_highlightNextHighlight = 0;
	_highlightGoThrough     = 0;
	[self syntaxHighlightTextStorage:textStorage startingAt:0];
}

- (void)replacedCharactersInRange:(NSRange)range newRangeLength:(NSUInteger)newRangeLength textStorage:(NSTextStorage*)textStorage {
	NSUInteger hash = [[textStorage string] hash];
	if (_lastHash == hash) {
		return;
	}
	_lastHash = hash;
	
	NSUInteger last = 0;
	NSUInteger lastLast = 0;
	NSUInteger i = 0;
	for (; i < [_resumePoints count]; ++i) {
		NSUInteger pos = [[_resumePoints objectAtIndex:i] unsignedIntegerValue];
		if (pos >= range.location) {
			// update the rest of the resume points, then break
			for (NSUInteger j = i; j < [_resumePoints count];) {
				pos = [[_resumePoints objectAtIndex:j] unsignedIntegerValue];
				if (pos < range.location + range.length) {
					[_resumePoints removeObjectAtIndex:j];
				} else {
					[_resumePoints setObject:[NSNumber numberWithUnsignedInteger:pos - range.length + newRangeLength] atIndexedSubscript:j];
					++j;
				}
			}
			break;
		}
		lastLast = last;
		last = pos;
	}

	// backtrack a little and start from there
	_highlightStopPosition  = [textStorage length];
	_highlightResumeIndex   = (i > 2 ? i - 2 : 0);
	_highlightNextHighlight = lastLast;
	_highlightGoThrough     = range.location + range.length;

	[textStorage beginEditing];
	[self syntaxHighlightTextStorage:textStorage startingAt:lastLast];
	
	if (_highlightStopPosition == [textStorage length]) {
		// remove the remaining resume points
		for (NSUInteger i = _highlightResumeIndex + 1; i < [_resumePoints count];) {
			[_resumePoints removeObjectAtIndex:i];
		}
	}

	// color in anything up until the stopping point
	Theme* theme = [Preferences sharedPreferences].theme;
	NSRange r = NSMakeRange(_highlightNextHighlight, _highlightStopPosition - _highlightNextHighlight);
	[textStorage removeAttribute:NSForegroundColorAttributeName range:r];
	[textStorage addAttribute:NSForegroundColorAttributeName value:theme.defaultColor range:r];
	[textStorage endEditing];
}

- (void)dealloc {
	self.keywords = nil;
	self.resumePoints = nil;

	[super dealloc];
}

@end
