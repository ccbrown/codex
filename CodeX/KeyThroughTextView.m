//
//  KeyThroughTextView.m
//  CodeX
//
//  Created by Christopher Brown on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KeyThroughTextView.h"

@implementation KeyThroughTextView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_keyDownEvent = nil;
    }
    
    return self;
}

- (void)keyDown:(NSEvent*)event {
	[_keyDownEvent release];
	_keyDownEvent = [event retain];
	[super keyDown:event];
}

- (void)doCommandBySelector:(SEL)selector {
	if (_keyDownEvent && selector == @selector(noop:)) {
		if ([self nextResponder]) {
			[[self nextResponder] keyDown:[_keyDownEvent autorelease]];
		} else {
			[_keyDownEvent release];
		}
		_keyDownEvent = nil;
	} else {
		[super doCommandBySelector:selector];
	}
}

- (void)dealloc {
	[_keyDownEvent release];
	
	[super dealloc];
}

@end
