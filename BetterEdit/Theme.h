//
//  Theme.h
//  BetterEdit
//
//  Created by Christopher Brown on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Theme : NSObject <NSCopying, NSCoding> {
	NSString* _name;
	
	NSFont* _font;
	
	NSColor* _defaultColor;
	NSColor* _keywordColor;
	NSColor* _commentColor;
	NSColor* _directiveColor;
	NSColor* _constantColor;
	NSColor* _quoteColor;
	NSColor* _functionColor;
	NSColor* _identifierColor;

	NSColor* _backgroundColor;
	NSColor* _selectionColor;
	NSColor* _cursorColor;
}

+ (NSArray*)templateNames;

- (id)initFromTemplate:(NSString*)template;

@property (nonatomic, copy) NSString* name;

@property (nonatomic, retain) NSFont* font;

@property (nonatomic, retain) NSColor* defaultColor;
@property (nonatomic, retain) NSColor* keywordColor;
@property (nonatomic, retain) NSColor* commentColor;
@property (nonatomic, retain) NSColor* directiveColor;
@property (nonatomic, retain) NSColor* constantColor;
@property (nonatomic, retain) NSColor* quoteColor;
@property (nonatomic, retain) NSColor* functionColor;
@property (nonatomic, retain) NSColor* identifierColor;

@property (nonatomic, retain) NSColor* backgroundColor;
@property (nonatomic, retain) NSColor* selectionColor;
@property (nonatomic, retain) NSColor* cursorColor;

@end