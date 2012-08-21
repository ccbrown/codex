//
//  FileTableCellView.h
//  BetterEdit
//
//  Created by Christopher Brown on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FileTableCellView : NSView {

	NSCell* _imageCell;
	NSCell* _textCell;
	
	NSCell* _rightTextCell;
}

- (void)setImage:(NSImage*)image;
- (void)setText:(NSString*)text;
- (void)setRightText:(NSString*)text;

@end
