//
//  FontTextField.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FontTextField.h"
#import "Preferences.h"

@implementation FontTextField

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_fontChangeTarget = nil;
    }
    
    return self;
}

- (void)setFontChangeTarget:(id)target {
	_fontChangeTarget = target;
}

- (BOOL)becomeFirstResponder {
	return YES;
}

- (BOOL)resignFirstResponder {
	[[NSFontPanel sharedFontPanel] close];
	return YES;
}

- (void)changeFont:(id)sender {
	if (_fontChangeTarget) {
		[_fontChangeTarget changeFont:sender];
	}
}

- (void)dealloc {
	[super dealloc];
}

@end
