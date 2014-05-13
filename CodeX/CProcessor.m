//
//  CProcessor.m
//  CodeX
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CProcessor.h"
#import "Preferences.h"

@implementation CProcessor

- (void)syntaxHighlightTextStorage:(NSTextStorage*)textStorage startingAt:(NSUInteger)position {
	Theme* theme = [Preferences sharedPreferences].theme;

	NSString* string = [textStorage string];
	
	NSUInteger length = [string length] - position;

	// for quotes and multi-line comments that return to directives when they end
	bool returnToDirective = false;

	NSUInteger i;
	
	while (length > 0 && length < 0x80000000) {
		if (!returnToDirective && ![self addResumePoint:position]) {
			return;
		}
		
		unichar c1 = [string characterAtIndex:position];
		unichar c2 = (length > 1 ? [string characterAtIndex:position + 1] : 'x');

		if (c1 == '/' && c2 == '/') {
			// single line comment

			for (i = 2; i < length; ++i) {
				if ([string characterAtIndex:position + i] == '\n' && [string characterAtIndex:position + i - 1] != '\\') {
					break;
				}
			}

			[self colorText:theme.commentColor atRange:NSMakeRange(position, i) textStorage:textStorage];
			position += i;
			length -= i;
		} else if (c1 == '/' && c2 == '*') {
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

			[self colorText:(c1 == '"' ? theme.quoteColor : theme.constantColor) atRange:NSMakeRange(position, quoteLength) textStorage:textStorage];

			position += quoteLength;
			length -= quoteLength;
		} else if (returnToDirective || c1 == '#') {
			// preprocessor directive
			
			returnToDirective = false;
			
			for (i = 0; i < length; ++i) {
				unichar ic1 = [string characterAtIndex:position + i];
				
				if (ic1 == '"' || ic1 == '\'') {
					// quote
					returnToDirective = true;
					break;
				}

				unichar ic2 = (i + 1 < length ? [string characterAtIndex:position + i + 1] : 'x');

				if (ic1 == '/' && ic2 == '/') {
					// single line comment
					break;
				}

				if (ic1 == '/' && ic2 == '*') {
					// multi line comment
					returnToDirective = true;
					break;
				}
				
				if (ic1 == '\n' && [string characterAtIndex:position + i - 1] != '\\') {
					// end of the directive
					break;
				}
			}
			
			[self colorText:theme.directiveColor atRange:NSMakeRange(position, i) textStorage:textStorage];

			position += i;
			length -= i;
		} else if ((c1 >= '0' && c1 <= '9') || (c1 == '.' && (c2 >= '0' && c2 <= '9'))) {
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
		} else if ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_') {
			// identifier

			for (i = 1; i < length; ++i) {
				unichar c = [string characterAtIndex:position + i];
				if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_')) {
					break;
				}
			}
			
			NSString* identifier = [string substringWithRange:NSMakeRange(position, i)];

			if ([self.keywords containsObject:identifier]) {
				[self colorText:theme.keywordColor atRange:NSMakeRange(position, i) textStorage:textStorage];
			} else {
				if (i < length && [string characterAtIndex:position + i] == '(') {
					// function call
					[self colorText:theme.functionColor atRange:NSMakeRange(position, i) textStorage:textStorage];
				} else {
					// variable / type
					[self colorText:theme.identifierColor atRange:NSMakeRange(position, i) textStorage:textStorage];
				}
			}
			position += i;
			length -= i;
		} else {
			++position;
			--length;
		}

	}
}

@end

