//
//  TextRulerView.h
//  CodeX
//
//  Created by Christopher Brown on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TextProcessor.h"

@interface TextRulerView : NSRulerView {
	NSTextView* _textView;

	// cache
	NSUInteger _lineNumber;
	NSUInteger _position;
	NSUInteger _column;
}

@end
