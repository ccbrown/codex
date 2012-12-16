//
//  EditingTextView.h
//  BetterEdit
//
//  Created by Christopher Brown on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "KeyThroughTextView.h"
#import "AdvancedFindPanel.h"

@protocol EditingTextViewDelegate <NSTextViewDelegate>

- (BOOL)textView:(NSTextView *)textView doKeyDownByEvent:(NSEvent*)event;

@end

@interface EditingTextView : KeyThroughTextView <AdvancedTextFinderClient>

@end
