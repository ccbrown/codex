//
//  CSSProcessor.m
//  CodeX
//
//  Created by Christopher Brown on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CSSProcessor.h"
#import "Preferences.h"

@implementation CSSProcessor

- (BOOL)document:(TextDocument *)document textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
	if (selector == @selector(toggleComment:)) {
		NSString* string = [textView string];

		NSRange selectedRange = [textView selectedRange];
		
		NSRange lineRange = [string lineRangeForRange:selectedRange];
		
		NSRange firstNonWhitespace = [string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet] options:0 range:lineRange];
		NSRange lastNonWhitespace  = [string rangeOfCharacterFromSet:[[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet] options:NSBackwardsSearch range:lineRange];
		
		if (firstNonWhitespace.location == NSNotFound) {
			return YES;
		}

		lineRange.location = firstNonWhitespace.location;
		lineRange.length   = lastNonWhitespace.location - firstNonWhitespace.location + 1;
		
		NSString* lines = [string substringWithRange:lineRange];
		
		NSString* replacement = @"";
		if ([lines length] >= 4 && [[lines substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"/*"] && [[lines substringWithRange:NSMakeRange([lines length] - 2, 2)] isEqualToString:@"*/"]) {
			// remove comment
			replacement = [lines substringWithRange:NSMakeRange(2, [lines length] - 4)];
		} else {
			// add comment
			replacement = [NSString stringWithFormat:@"/*%@*/", lines];
		}
		
		if ([textView shouldChangeTextInRange:lineRange replacementString:replacement]) {
			[textView replaceCharactersInRange:lineRange withString:replacement];
			[textView didChangeText];

			[textView setSelectedRange:NSMakeRange(lineRange.location, [replacement length])];
		}

		return YES;
	}
	
	return [super document:document textView:textView doCommandBySelector:selector];
}

- (void)syntaxHighlightTextStorage:(NSTextStorage*)textStorage startingAt:(NSUInteger)position {
	Theme* theme = [Preferences sharedPreferences].theme;
	
	NSString* string = [textStorage string];
	
	NSUInteger length = [string length] - position;
	
	NSUInteger i;
	
	BOOL inBrackets = NO;
	BOOL postColon = NO;
	
	while (length > 0 && length < 0x80000000) {
		if (!inBrackets && !postColon && ![self addResumePoint:position]) {
			return;
		}

		unichar c1 = [string characterAtIndex:position];
		unichar c2 = (length > 1 ? [string characterAtIndex:position + 1] : 'x');
		
		if (c1 == '/' && c2 == '*') {
			// multi line comment
			
			for (i = 2; i < length; ++i) {
				if ([string characterAtIndex:position + i - 1] == '*' && [string characterAtIndex:position + i] == '/') {
					break;
				}
			}

			[self colorText:theme.commentColor atRange:NSMakeRange(position, MIN(i + 1, length)) textStorage:textStorage];

			position += i;
			length -= i;
		} else if (c1 == '"' || c1 == '\'') {
			// quote
			
			NSUInteger quoteLength = [self quoteLength:string range:NSMakeRange(position, length)];
			
			[self colorText:theme.quoteColor atRange:NSMakeRange(position, quoteLength) textStorage:textStorage];
			
			position += quoteLength;
			length -= quoteLength;
		} else if (inBrackets && ((c1 >= '0' && c1 <= '9') || (c1 == '.' && (c2 >= '0' && c2 <= '9')) || c1 == '#')) {
			// number
			
			for (i = 1; i < length; ++i) {
				unichar c = [string characterAtIndex:position + i];
				if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '.')) {
					break;
				}
			}

			[self colorText:theme.constantColor atRange:NSMakeRange(position, i) textStorage:textStorage];

			position += i;
			length -= i;
		} else if ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_' || c1 == '-') {
			// identifier
			
			for (i = 1; i < length; ++i) {
				unichar c = [string characterAtIndex:position + i];
				if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-')) {
					break;
				}
			}
			
			if (inBrackets) {
				if (i < length && [string characterAtIndex:position + i] == '(') {
					// function
					[self colorText:theme.functionColor atRange:NSMakeRange(position, i) textStorage:textStorage];
				} else {
					// other
					[self colorText:(postColon ? theme.defaultColor : [theme.defaultColor colorWithAlphaComponent:0.7]) atRange:NSMakeRange(position, i) textStorage:textStorage];
				}
			} else {
				if (position > 0 && ([string characterAtIndex:position - 1] == '#' || [string characterAtIndex:position - 1] == '.')) {
					// class / id
					[self colorText:theme.identifierColor atRange:NSMakeRange(position, i) textStorage:textStorage];
				} else {
					// tag / pseudo class
					[self colorText:theme.keywordColor atRange:NSMakeRange(position, i) textStorage:textStorage];
				}
			}

			position += i;
			length -= i;
		} else {
			if (c1 == '{') {
				inBrackets = YES;
			} else if (c1 == '}') {
				inBrackets = NO;
			}
			if (c1 == ':') {
				postColon = YES;
			} else if (c1 == '\n' || c1 == '\r' || c1 == ';') {
				postColon = NO;
			}
			++position;
			--length;
		}
		
	}
}

@end
