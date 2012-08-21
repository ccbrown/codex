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

@synthesize keywords = _keywords, singleLineCommentPrefix = _singleLineCommentPrefix;

- (id)init {
	if (self = [super init]) {
		[self invalidateHash];
		
		self.keywords = nil;
		self.singleLineCommentPrefix = @"//";
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

- (void)formatTextStorage:(NSTextStorage*)textStorage {
	[self formatTextStorage:textStorage range:NSMakeRange(0, [textStorage length])];
}

- (void)formatTextStorage:(NSTextStorage*)textStorage range:(NSRange)range {
	if (![self prepareToProcessText:textStorage]) {
		return;
	}
	
	if (range.length < 1) {
		return;
	}
	
	Theme* theme = [Preferences sharedPreferences].theme;
	
	[textStorage removeAttribute:NSForegroundColorAttributeName range:range];
	[textStorage addAttribute:NSForegroundColorAttributeName value:theme.defaultColor range:range];
	
	NSString* string = [textStorage string];
	
	while (range.length > 0 && range.length < 0x80000000) {
		unichar c1 = [string characterAtIndex:range.location];
		
		if (c1 == '"') {
			// quote
			
			NSUInteger quoteLength = [self quoteLength:string range:range];
			
			[textStorage addAttribute:NSForegroundColorAttributeName value:(c1 == '"' ? theme.quoteColor : theme.constantColor) range:NSMakeRange(range.location, quoteLength)];
			
			range.location += quoteLength;
			range.length -= quoteLength;
		} else {
			++range.location;
			--range.length;
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

- (void)invalidateHash {
	_hash = 0;
}

- (BOOL)prepareToProcessText:(NSTextStorage*)text {
	if ([text hash] != _hash) {
		_hash = [text hash];
		return YES;
	}

	return NO;
}

- (void)dealloc {	
	self.keywords = nil;

	[super dealloc];
}

@end
