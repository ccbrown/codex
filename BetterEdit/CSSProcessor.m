//
//  CSSProcessor.m
//  BetterEdit
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
	NSUInteger i;
	
	BOOL inBrackets = NO;
	BOOL postSemiColon = NO;
	
	while (range.length > 0 && range.length < 0x80000000) {
		unichar c1 = [string characterAtIndex:range.location];
		unichar c2 = (range.length > 1 ? [string characterAtIndex:range.location + 1] : 'x');
		
		if (c1 == '/' && c2 == '*') {
			// multi line comment
			
			for (i = 2; i < range.length; ++i) {
				if ([string characterAtIndex:range.location + i - 1] == '*' && [string characterAtIndex:range.location + i] == '/') {
					break;
				}
			}

			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.commentColor range:NSMakeRange(range.location, MIN(i + 1, range.length))];
			range.location += i;
			range.length -= i;
		} else if (c1 == '"' || c1 == '\'') {
			// quote
			
			NSUInteger quoteLength = [self quoteLength:string range:range];
			
			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.quoteColor range:NSMakeRange(range.location, quoteLength)];
			
			range.location += quoteLength;
			range.length -= quoteLength;
		} else if (inBrackets && ((c1 >= '0' && c1 <= '9') || (c1 == '.' && (c2 >= '0' && c2 <= '9')) || c1 == '#')) {
			// number
			
			for (i = 1; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
				if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '.')) {
					break;
				}
			}

			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.constantColor range:NSMakeRange(range.location, i)];
			range.location += i;
			range.length -= i;
		} else if ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_' || c1 == '-') {
			// identifier
			
			for (i = 1; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
				if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-')) {
					break;
				}
			}
			
			if (inBrackets) {
				if (i < range.length && [string characterAtIndex:range.location + i] == '(') {
					// function
					[textStorage addAttribute:NSForegroundColorAttributeName value:theme.functionColor range:NSMakeRange(range.location, i)];
				} else {
					// other
					[textStorage addAttribute:NSForegroundColorAttributeName value:(postSemiColon ? theme.defaultColor : [theme.defaultColor colorWithAlphaComponent:0.7]) range:NSMakeRange(range.location, i)];
				}
			} else {
				if (range.location > 0 && ([string characterAtIndex:range.location - 1] == '#' || [string characterAtIndex:range.location - 1] == '.')) {
					// class / id
					[textStorage addAttribute:NSForegroundColorAttributeName value:theme.identifierColor range:NSMakeRange(range.location, i)];
				} else {
					// tag / pseudo class
					[textStorage addAttribute:NSForegroundColorAttributeName value:theme.keywordColor range:NSMakeRange(range.location, i)];
				}
			}

			range.location += i;
			range.length -= i;
		} else {
			if (c1 == '{') {
				inBrackets = YES;
			} else if (c1 == '}') {
				inBrackets = NO;
			}
			if (c1 == ':') {
				postSemiColon = YES;
			} else if (c1 == '\n' || c1 == '\r' || c1 == ';') {
				postSemiColon = NO;
			}
			++range.location;
			--range.length;
		}
		
	}
}

@end
