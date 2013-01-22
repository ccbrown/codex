//
//  PHPProcessor.m
//  BetterEdit
//
//  Created by Christopher Brown on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PHPProcessor.h"
#import "Preferences.h"

@implementation PHPProcessor

// quotes aren't terminated by newlines
- (NSUInteger)phpQuoteLength:(NSString*)string range:(NSRange)range {
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

- (void)phpSyntaxHighlightTextStorage:(NSTextStorage*)textStorage range:(NSRange)range {
	Theme* theme = [Preferences sharedPreferences].theme;
	
	NSString* string = [textStorage string];
	
	NSUInteger i;

	while (range.length > 0) {
		unichar c1 = [string characterAtIndex:range.location];
		unichar c2 = (range.length > 1 ? [string characterAtIndex:range.location + 1] : 'x');
		
		if (c1 == '/' && c2 == '/') {
			// single line comment
			
			for (i = 2; i < range.length; ++i) {
				if ([string characterAtIndex:range.location + i] == '\n' && [string characterAtIndex:range.location + i - 1] != '\\') {
					break;
				}
			}
			
			[self colorText:[theme.commentColor colorWithAlphaComponent:0.8] atRange:NSMakeRange(range.location, i) textStorage:textStorage];

			range.location += i;
			range.length -= i;
		} else if (c1 == '/' && c2 == '*') {
			// multi line comment
			
			for (i = 2; i < range.length; ++i) {
				if ([string characterAtIndex:range.location + i - 1] == '*' && [string characterAtIndex:range.location + i] == '/') {
					break;
				}
			}
			
			[self colorText:[theme.commentColor colorWithAlphaComponent:0.8] atRange:NSMakeRange(range.location, MIN(i + 1, range.length)) textStorage:textStorage];

			range.location += i;
			range.length -= i;
		} else if (c1 == '"' || c1 == '\'') {
			// quote
			
			NSUInteger quoteLength = [self phpQuoteLength:string range:NSMakeRange(range.location, range.length)];
			
			[self colorText:[theme.quoteColor colorWithAlphaComponent:0.8] atRange:NSMakeRange(range.location, quoteLength) textStorage:textStorage];
			
			range.location += quoteLength;
			range.length -= quoteLength;
		} else if ((c1 >= '0' && c1 <= '9') || (c1 == '.' && (c2 >= '0' && c2 <= '9'))) {
			// number
			
			for (i = 1; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
				if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '.')) {
					break;
				}
			}
			
			[self colorText:[theme.constantColor colorWithAlphaComponent:0.8] atRange:NSMakeRange(range.location, i) textStorage:textStorage];

			range.location += i;
			range.length -= i;
		} else if ((c1 >= 'a' && c1 <= 'z') || (c1 >= 'A' && c1 <= 'Z') || c1 == '_' || c1 == '$') {
			// identifier

			for (i = 1; i < range.length; ++i) {
				unichar c = [string characterAtIndex:range.location + i];
				if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '$')) {
					break;
				}
			}
			
			NSString* identifier = [string substringWithRange:NSMakeRange(range.location, i)];
			
			if ([self.keywords containsObject:identifier]) {
				[self colorText:[theme.keywordColor colorWithAlphaComponent:0.8] atRange:NSMakeRange(range.location, i) textStorage:textStorage];
			} else {
				if (i < range.length && [string characterAtIndex:range.location + i] == '(') {
					// function call
					[self colorText:[theme.functionColor colorWithAlphaComponent:0.8] atRange:NSMakeRange(range.location, i) textStorage:textStorage];
				} else {
					// variable / type
					[self colorText:[theme.identifierColor colorWithAlphaComponent:0.8] atRange:NSMakeRange(range.location, i) textStorage:textStorage];
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
			// php tag

			for (i = 2; i < length; ++i) {
				unichar c = [string characterAtIndex:position + i];
				if (c == '"' || c == '\'') {
					i += [self quoteLength:string range:NSMakeRange(position + i, length - i)];
					if (i >= length) {
						break;
					}
					c = [string characterAtIndex:position + i];
				}
				if (c == '>' && ([string characterAtIndex:position + 1] != '?' || [string characterAtIndex:position + i - 1] == '?')) {
					break;
				}
			}
			
			if ([string characterAtIndex:position + 1] == '?') {
				[self phpSyntaxHighlightTextStorage:textStorage range:NSMakeRange(position, MIN(length, i + 1))];
			} else {
				[self colorText:theme.directiveColor atRange:NSMakeRange(position, MIN(length, i + 1)) textStorage:textStorage];
			}
			
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
