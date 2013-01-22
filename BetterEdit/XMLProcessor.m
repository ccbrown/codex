//
//  XMLProcessor.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMLProcessor.h"
#import "Preferences.h"

@implementation XMLProcessor

- (BOOL)document:(TextDocument *)document textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
	if (selector == @selector(toggleComment:)) {
		NSBeep();
		return NO;
	}
	
	return [super document:document textView:textView doCommandBySelector:selector];
}

- (void)syntaxHighlightTextStorage:(NSTextStorage*)textStorage startingAt:(NSUInteger)position {
	Theme* theme = [Preferences sharedPreferences].theme;
	
	NSString* string = [textStorage string];
	
	NSUInteger length = [string length] - position;
	
	NSUInteger i;

	enum {
		XMLStateNormal,
		XMLStateTag,
	};
	NSUInteger state = XMLStateNormal;
	
	while (length > 0 && length < 0x80000000) {
		if (state == XMLStateNormal && ![self addResumePoint:position]) {
			return;
		}

		unichar c1 = [string characterAtIndex:position];
		
		if (state == XMLStateTag && ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_' || c1 == ':')) {
			// attribute
			for (i = 1; i < length; ++i) {
				unichar c = [string characterAtIndex:position + i];
				if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == ':' || c == '-' || c == '.')) {
					break;
				}
			}

			[self colorText:theme.identifierColor atRange:NSMakeRange(position, i) textStorage:textStorage];

			position += i;
			length -= i;
		} else if (state == XMLStateTag && c1 == '=' && length >= 2) {
			// attribute value

			for (i = 1; i < length; ++i) {
				if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[string characterAtIndex:position + i]]) {
					break;
				}
			}

			unichar c = [string characterAtIndex:position + i];
			if (c == '"' || c == '\'') {
				i += [self quoteLength:string range:NSMakeRange(position + i, length - i)];
				[self colorText:theme.quoteColor atRange:NSMakeRange(position + 1, i - 1) textStorage:textStorage];
			} else {
				for (; i < length; ++i) {
					c = [string characterAtIndex:position + i];
					if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c] || c == '>' || c == '/') {
						break;
					}
				}
				[self colorText:theme.constantColor atRange:NSMakeRange(position + 1, i - 1) textStorage:textStorage];
			}
			
			position += i;
			length -= i;
		} else if (state == XMLStateTag && c1 == '>') {
			state = XMLStateNormal;

			position += 1;
			length -= 1;
		} else if (state == XMLStateNormal && c1 == '<' && length >= 4 && [[string substringWithRange:NSMakeRange(position, 4)] compare:@"<!--"] == NSOrderedSame) {
			// comment
			
			NSRange matchRange = [string rangeOfString:@"-->" options:NSLiteralSearch range:NSMakeRange(position, length)];
			
			NSUInteger l;
			if (matchRange.location == NSNotFound) {
				l = length;
			} else {
				l = matchRange.location + matchRange.length - position;
			}

			[self colorText:theme.commentColor atRange:NSMakeRange(position, l) textStorage:textStorage];
			
			position += l;
			length -= l;
		} else if (state == XMLStateNormal && c1 == '<' && length >= 2 && ([string characterAtIndex:position + 1] == '?' || [string characterAtIndex:position + 1] == '!')) {
			// directive
			
			for (i = 2; i < length; ++i) {
				unichar c = [string characterAtIndex:position + i];
				if (c == '"') {
					i += [self quoteLength:string range:NSMakeRange(position + i, length - i)];
					if (i >= length) {
						break;
					}
					c = [string characterAtIndex:position + i];
				}
				if (c == '>') {
					break;
				}
			}

			[self colorText:theme.directiveColor atRange:NSMakeRange(position, MIN(length, i + 1)) textStorage:textStorage];

			position += (i + 1);
			length -= (i + 1);
		} else if (state == XMLStateNormal && c1 == '<') {
			// possible tag
			
			NSUInteger start = position + 1;
			BOOL isATag = YES;
			
			for (i = 1; i < length; ++i) {
				unichar c = [string characterAtIndex:position + i];
				if (c == '/') {
					++start;
				} else if (c >= '0' && c <= '9') {
					isATag = NO;
					break;
				} else if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c]) {
					break;
				}
			}

			if (isATag) {
				for (; i < length; ++i) {
					unichar c = [string characterAtIndex:position + i];
					if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == ':' || c == '-' || c == '.')) {
						isATag = ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c] || c == '>' || c == '/');
						break;
					}
				}

				if (isATag) {
					[self colorText:theme.keywordColor atRange:NSMakeRange(start, i - (start - position)) textStorage:textStorage];

					state = (start - position > 0 ? XMLStateTag : state);
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
