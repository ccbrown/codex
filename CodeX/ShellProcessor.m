//
//  ShellProcessor.m
//  CodeX
//
//  Created by Christopher Brown on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ShellProcessor.h"
#import "Preferences.h"

@implementation ShellProcessor

- (id)init {
	if (self = [super init]) {
		self.singleLineCommentPrefix = @"#";
	}

	return self;
}

- (void)syntaxHighlightTextStorage:(NSTextStorage*)textStorage startingAt:(NSUInteger)position {
	Theme* theme = [Preferences sharedPreferences].theme;
	
	NSString* string = [textStorage string];
	
	NSUInteger length = [string length] - position;

	NSUInteger i;
	
	while (length > 0 && length < 0x80000000) {
		if (![self addResumePoint:position]) {
			return;
		}

		unichar c1 = [string characterAtIndex:position];
		unichar c2 = (length > 1 ? [string characterAtIndex:position + 1] : 'x');
		
		if (c1 == '#' && c2 == '!') {
			// shebang

			for (i = 2; i < length; ++i) {
				if ([string characterAtIndex:position + i] == '\n') {
					break;
				}
			}
			
			[self colorText:theme.directiveColor atRange:NSMakeRange(position, i) textStorage:textStorage];

			position += i;
			length -= i;
		} else if (c1 == '#') {
			// single line comment
				
			for (i = 1; i < length; ++i) {
				if ([string characterAtIndex:position + i] == '\n') {
					break;
				}
			}
				
			[self colorText:theme.commentColor atRange:NSMakeRange(position, i) textStorage:textStorage];

			position += i;
			length -= i;
		} else if (c1 == '"' || c1 == '\'') {
			// quote
			
			NSUInteger quoteLength = [self quoteLength:string range:NSMakeRange(position, length)];
			
			[self colorText:theme.quoteColor atRange:NSMakeRange(position, quoteLength) textStorage:textStorage];
			
			position += quoteLength;
			length -= quoteLength;
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
		} else if ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_' || c1 == '$') {
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
				if (c1 == '$') {
					// variable
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

