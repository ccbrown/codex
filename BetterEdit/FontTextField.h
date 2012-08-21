//
//  FontTextField.h
//  BetterEdit
//
//  Created by Christopher Brown on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FontTextField : NSTextField {
	id _fontChangeTarget;
}

- (void)setFontChangeTarget:(id)target;

@end
