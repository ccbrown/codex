//
//  CProcessor.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CProcessor.h"
#import "Preferences.h"

@implementation CProcessor

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

	// for quotes and multi-line comments that return to directives when they end
	bool returnToDirective = false;

	NSString* string = [textStorage string];
	NSUInteger i;
	
	while (range.length > 0 && range.length < 0x80000000) {
		unichar c1 = [string characterAtIndex:range.location];
		unichar c2 = (range.length > 1 ? [string characterAtIndex:range.location + 1] : 'x');

		if (c1 == '/' && c2 == '/') {
			// single line comment

			for (i = 2; i < range.length; ++i) {
				if ([string characterAtIndex:range.location + i] == '\n' && [string characterAtIndex:range.location + i - 1] != '\\') {
					break;
				}
			}

			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.commentColor range:NSMakeRange(range.location, i)];
			range.location += i;
			range.length -= i;
		} else if (c1 == '/' && c2 == '*') {
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

			[textStorage addAttribute:NSForegroundColorAttributeName value:(c1 == '"' ? theme.quoteColor : theme.constantColor) range:NSMakeRange(range.location, quoteLength)];

			range.location += quoteLength;
			range.length -= quoteLength;
		} else if (returnToDirective || c1 == '#') {
			// preprocessor directive
			
			returnToDirective = false;
			
			for (i = 0; i < range.length; ++i) {
				unichar ic1 = [string characterAtIndex:range.location + i];
				
				if (ic1 == '"' || ic1 == '\'') {
					// quote
					returnToDirective = true;
					break;
				}

				unichar ic2 = (i + 1 < range.length ? [string characterAtIndex:range.location + i + 1] : 'x');

				if (ic1 == '/' && ic2 == '/') {
					// single line comment
					break;
				}

				if (ic1 == '/' && ic2 == '*') {
					// multi line comment
					returnToDirective = true;
					break;
				}
				
				if (ic1 == '\n' && [string characterAtIndex:range.location + i - 1] != '\\') {
					// end of the directive
					break;
				}
			}
			
			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.directiveColor range:NSMakeRange(range.location, i)];
			range.location += i;
			range.length -= i;
		} else if ((c1 >= '0' && c1 <= '9') || (c1 == '.' && (c2 >= '0' && c2 <= '9'))) {
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
		} else if ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_') {
			// identifier

			for (i = 1; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
				if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_')) {
					break;
				}
			}
			
			NSString* identifier = [string substringWithRange:NSMakeRange(range.location, i)];

			if ([self.keywords containsObject:identifier]) {
				[textStorage addAttribute:NSForegroundColorAttributeName value:theme.keywordColor range:NSMakeRange(range.location, i)];
			} else {
				if (i < range.length && [string characterAtIndex:range.location + i] == '(') {
					// function call
					[textStorage addAttribute:NSForegroundColorAttributeName value:theme.functionColor range:NSMakeRange(range.location, i)];
				} else {
					// variable / type
					[textStorage addAttribute:NSForegroundColorAttributeName value:theme.identifierColor range:NSMakeRange(range.location, i)];
				}
			}
			range.location += i;
			range.length -= i;
		} else {
			++range.location;
			--range.length;
		}

	}
}

@end

