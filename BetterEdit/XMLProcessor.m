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

	enum {
		XMLStateNormal,
		XMLStateTag,
	};
	NSUInteger state = XMLStateNormal;
	
	while (range.length > 0 && range.length < 0x80000000) {
		unichar c1 = [string characterAtIndex:range.location];
		
		if (state == XMLStateTag && ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_' || c1 == ':')) {
			// attribute
			for (i = 1; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
				if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == ':' || c == '-' || c == '.')) {
					break;
				}
			}

			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.identifierColor range:NSMakeRange(range.location, i)];
			range.location += i;
			range.length -= i;
		} else if (state == XMLStateTag && c1 == '=') {
			// attribute value

			for (i = 1; i < range.length; ++i) {
				if (![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[string characterAtIndex:range.location + i]]) {
					break;
				}
			}

			unichar c = [string characterAtIndex:range.location + i];
			if (c == '"' || c == '\'') {
				i += [self quoteLength:string range:NSMakeRange(range.location + i, range.length - i)];
				[textStorage addAttribute:NSForegroundColorAttributeName value:theme.quoteColor range:NSMakeRange(range.location + 1, i - 1)];
			} else {
				for (; i < range.length; ++i) {
					c = [string characterAtIndex:range.location + i];
					if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c] || c == '>' || c == '/') {
						break;
					}
				}
				[textStorage addAttribute:NSForegroundColorAttributeName value:theme.constantColor range:NSMakeRange(range.location + 1, i - 1)];
			}
			
			range.location += i;
			range.length -= i;
		} else if (state == XMLStateTag && c1 == '>') {
			state = XMLStateNormal;

			range.location += 1;
			range.length -= 1;
		} else if (state == XMLStateNormal && c1 == '<' && range.length >= 4 && [[string substringWithRange:NSMakeRange(range.location, 4)] compare:@"<!--"] == NSOrderedSame) {
			// comment
			
			NSRange matchRange = [string rangeOfString:@"-->" options:NSLiteralSearch range:range];
			
			NSUInteger length;
			if (matchRange.location == NSNotFound) {
				length = range.length;
			} else {
				length = matchRange.location + matchRange.length - range.location;
			}

			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.commentColor range:NSMakeRange(range.location, length)];
			
			range.location += length;
			range.length -= length;
		} else if (state == XMLStateNormal && c1 == '<' && range.length >= 2 && ([string characterAtIndex:range.location + 1] == '?' || [string characterAtIndex:range.location + 1] == '!')) {
			// directive
			
			for (i = 2; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
				if (c == '"') {
					i += [self quoteLength:string range:NSMakeRange(range.location + i, range.length - i)];
					if (i >= range.length) {
						break;
					}
					c = [string characterAtIndex:range.location + i];
				}
				if (c == '>') {
					break;
				}
			}

			[textStorage addAttribute:NSForegroundColorAttributeName value:theme.directiveColor range:NSMakeRange(range.location, MIN(range.length, i + 1))];
			range.location += (i + 1);
			range.length -= (i + 1);
		} else if (state == XMLStateNormal && c1 == '<') {
			// possible tag
			
			NSUInteger start = range.location + 1;
			BOOL isATag = YES;
			
			for (i = 1; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
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
				for (; i < range.length; ++i) {
					unichar c = [string characterAtIndex:range.location + i];
					if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == ':' || c == '-' || c == '.')) {
						isATag = ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c] || c == '>' || c == '/');
						break;
					}
				}

				if (isATag) {
					[textStorage addAttribute:NSForegroundColorAttributeName value:theme.keywordColor range:NSMakeRange(start, i - (start - range.location))];

					state = (start - range.location > 0 ? XMLStateTag : state);
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
