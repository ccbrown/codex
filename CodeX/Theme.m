//
//  Theme.m
//  CodeX
//
//  Created by Christopher Brown on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Theme.h"

@implementation Theme

@synthesize name = _name, font = _font, defaultColor = _defaultColor, keywordColor = _keywordColor, commentColor = _commentColor, 
directiveColor = _directiveColor, constantColor = _constantColor, quoteColor = _quoteColor, functionColor = _functionColor, 
identifierColor = _identifierColor, backgroundColor = _backgroundColor, selectionColor = _selectionColor, cursorColor = _cursorColor;

+ (NSArray*)templateNames {
	return [NSArray arrayWithObjects:@"Default", nil];
}

- (id)initFromTemplate:(NSString*)template {
	if (![[Theme templateNames] containsObject:template]) {
		[self release];
		return nil;
	}

	if (self = [self init]) {
		self.name = template;
		
		self.font = [NSFont fontWithName:@"Menlo" size:11.0];
		
		self.defaultColor    = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];
		self.keywordColor    = [NSColor colorWithDeviceRed:0.8 green:0.3 blue:0.0 alpha:1.0];
		self.commentColor    = [NSColor colorWithDeviceRed:0.0 green:0.5 blue:0.0 alpha:1.0];
		self.directiveColor  = [NSColor colorWithDeviceRed:0.5 green:0.2 blue:0.0 alpha:1.0];
		self.constantColor   = [NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.7 alpha:1.0];
		self.quoteColor      = [NSColor colorWithDeviceRed:0.9 green:0.0 blue:0.0 alpha:1.0];
		self.functionColor   = [NSColor colorWithDeviceRed:0.5 green:0.2 blue:0.5 alpha:1.0];
		self.identifierColor = [NSColor colorWithDeviceRed:0.0 green:0.2 blue:0.1 alpha:1.0];

		self.backgroundColor = [NSColor colorWithDeviceRed:1.0  green:1.0  blue:1.0  alpha:1.0];
		self.selectionColor  = [NSColor colorWithDeviceRed:0.72 green:0.85 blue:1.0  alpha:1.0];
		self.cursorColor     = [NSColor colorWithDeviceRed:0.0  green:0.0  blue:0.0  alpha:1.0];
	}

	return self;
}

- (Theme*)copyWithZone:(NSZone*)zone {
	Theme* copy = [Theme new];

	copy.name = self.name;

	copy.font = self.font;
	
	copy.defaultColor    = self.defaultColor;
	copy.keywordColor    = self.keywordColor;
	copy.commentColor    = self.commentColor;
	copy.directiveColor  = self.directiveColor;
	copy.constantColor   = self.constantColor;
	copy.quoteColor      = self.quoteColor;
	copy.functionColor   = self.functionColor;
	copy.identifierColor = self.identifierColor;
	
	copy.backgroundColor = self.backgroundColor;
	copy.selectionColor  = self.selectionColor;
	copy.cursorColor     = self.cursorColor;
	
	return copy;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		self.name = [decoder decodeObjectForKey:@"name"];
		
		self.font = [decoder decodeObjectForKey:@"font"];

		self.defaultColor    = [decoder decodeObjectForKey:@"defaultColor"];
		self.keywordColor    = [decoder decodeObjectForKey:@"keywordColor"];
		self.commentColor    = [decoder decodeObjectForKey:@"commentColor"];
		self.directiveColor  = [decoder decodeObjectForKey:@"directiveColor"];
		self.constantColor   = [decoder decodeObjectForKey:@"constantColor"];
		self.quoteColor      = [decoder decodeObjectForKey:@"quoteColor"];
		self.functionColor   = [decoder decodeObjectForKey:@"functionColor"];
		self.identifierColor = [decoder decodeObjectForKey:@"identifierColor"];
		
		self.backgroundColor = [decoder decodeObjectForKey:@"backgroundColor"];
		self.selectionColor  = [decoder decodeObjectForKey:@"selectionColor"];
		self.cursorColor     = [decoder decodeObjectForKey:@"cursorColor"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:self.name forKey:@"name"];
	[encoder encodeObject:self.font forKey:@"font"];
	
	[encoder encodeObject:self.defaultColor    forKey:@"defaultColor"];
	[encoder encodeObject:self.keywordColor    forKey:@"keywordColor"];
	[encoder encodeObject:self.commentColor    forKey:@"commentColor"];
	[encoder encodeObject:self.directiveColor  forKey:@"directiveColor"];
	[encoder encodeObject:self.constantColor   forKey:@"constantColor"];
	[encoder encodeObject:self.quoteColor      forKey:@"quoteColor"];
	[encoder encodeObject:self.functionColor   forKey:@"functionColor"];
	[encoder encodeObject:self.identifierColor forKey:@"identifierColor"];

	[encoder encodeObject:self.backgroundColor forKey:@"backgroundColor"];
	[encoder encodeObject:self.selectionColor  forKey:@"selectionColor"];
	[encoder encodeObject:self.cursorColor     forKey:@"cursorColor"];
}

- (void)dealloc {
	self.name = nil;
	self.font = nil;
	
	self.keywordColor    = nil;
	self.commentColor    = nil;
	self.directiveColor  = nil;
	self.constantColor   = nil;
	self.quoteColor      = nil;
	self.functionColor   = nil;
	self.identifierColor = nil;
	
	self.backgroundColor = nil;
	self.selectionColor  = nil;
	self.cursorColor     = nil;
	
	[super dealloc];
}

@end
