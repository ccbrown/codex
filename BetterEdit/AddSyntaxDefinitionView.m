//
//  AddSyntaxDefinitionView.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AddSyntaxDefinitionView.h"
#import "SyntaxDefinition.h"

@implementation AddSyntaxDefinitionView

@synthesize duplicateButton = _duplicateButton;

- (id)initWithFrame:(NSRect)frame {
	NSArray* templates = [SyntaxDefinition templateNames];
    if (self = [super initWithFrame:NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, 73.0 + 39.0 * [templates count])]) {
        // Initialization code here.
		_templateButtons = [[NSMutableArray arrayWithCapacity:[templates count]] retain];
		
		CGFloat y = [templates count] * 39.0 - 19.0;
		for (NSString* template in templates) {
			NSButton* button = [[NSButton alloc] initWithFrame:NSMakeRect(20.0, y, self.frame.size.width - 40.0, 19.0)];
			[button setBezelStyle:NSRoundRectBezelStyle];
			[button setRefusesFirstResponder:YES];
			[button setTitle:template];
			[button setTarget:self];
			[button setAction:@selector(buttonAction:)];
			[self addSubview:button];
			[_templateButtons addObject:button];
			[button release];
			y -= 39.0;
		}
    }
    
    return self;
}

- (void)popoverWillShow:(NSNotification *)notification {
	if (_delegate && [_delegate respondsToSelector:@selector(shouldEnableDuplicateButton)]) {
		[_duplicateButton setEnabled:[_delegate shouldEnableDuplicateButton]];
	} else {
		[_duplicateButton setEnabled:YES];
	}
}

- (IBAction)buttonAction:(NSButton*)sender {
	if (sender == _duplicateButton) {
		if (_delegate && [_delegate respondsToSelector:@selector(duplicateDefinition)]) {
			[_delegate duplicateDefinition];
		}
	} else {
		if (_delegate && [_delegate respondsToSelector:@selector(createDefinitionFromTemplate:)]) {
			NSUInteger index = [_templateButtons indexOfObject:sender];
			[_delegate createDefinitionFromTemplate:[[SyntaxDefinition templateNames] objectAtIndex:index]];
		}
	}
}

- (void)dealloc {
	[_templateButtons release];
	
	[super dealloc];
}

@end
