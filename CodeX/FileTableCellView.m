//
//  FileTableCellView.m
//  CodeX
//
//  Created by Christopher Brown on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileTableCellView.h"

@implementation FileTableCellView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

        // Initialization code here.
		_imageCell = [[NSCell alloc] initImageCell:nil];

		_textCell = [[NSCell alloc] initTextCell:@""];
		[_textCell setEditable:NO];
		[_textCell setTruncatesLastVisibleLine:YES];
		[_textCell setFont:[NSFont systemFontOfSize:11.0]];

		_rightTextCell = [[NSCell alloc] initTextCell:@""];
		[_rightTextCell setEditable:NO];
		[_rightTextCell setAlignment:NSRightTextAlignment];
		[_textCell setFont:[NSFont systemFontOfSize:11.0]];
	}

    return self;
}

- (void)setBackgroundStyle:(NSBackgroundStyle)style {
	NSColor* color;
	
	if (style == NSBackgroundStyleDark) {
		color = [NSColor whiteColor];
	} else {
		color = [NSColor blackColor];
	}

	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: color, NSForegroundColorAttributeName, nil];
	NSAttributedString* string = [[[NSAttributedString alloc] initWithString:[_textCell stringValue] attributes:attributes] autorelease];
	[_textCell setAttributedStringValue:string];
}

- (void)drawRect:(NSRect)rect {
	[_imageCell drawWithFrame:NSMakeRect(4.0, 3.0, _imageCell.image.size.width, _imageCell.image.size.height) inView:self];
	
	NSSize cellSize = [_textCell cellSizeForBounds:NSMakeRect(0.0, 0.0, self.frame.size.width - 38.0, self.frame.size.height)];
	NSSize rightCellSize = [_rightTextCell cellSizeForBounds:NSMakeRect(0.0, 0.0, 200.0, self.frame.size.height)];

	[_textCell drawWithFrame:NSMakeRect(38.0, 0.5 * (self.frame.size.height - cellSize.height) + 0.5, self.frame.size.width - 38.0 - rightCellSize.width - 4.0, cellSize.height) inView:self];

	[_rightTextCell drawWithFrame:NSMakeRect(self.frame.size.width - rightCellSize.width - 4.0, 0.5 * (self.frame.size.height - rightCellSize.height) + 0.5, rightCellSize.width, rightCellSize.height) inView:self];
}

- (void)setImage:(NSImage*)image {	
	_imageCell.image = image;
}

- (void)setText:(NSString*)text {
	[_textCell setStringValue:text];
}

- (void)setRightText:(NSString*)text {
	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor grayColor], NSForegroundColorAttributeName, nil];
	NSAttributedString* string = [[[NSAttributedString alloc] initWithString:text attributes:attributes] autorelease];
	[_rightTextCell setAttributedStringValue:string];
}

- (void)dealloc {
	[_imageCell release];
	[_textCell release];
	
	[_rightTextCell release];

	[super dealloc];
}

@end
