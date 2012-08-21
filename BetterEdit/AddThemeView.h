//
//  AddThemeView.h
//  BetterEdit
//
//  Created by Christopher Brown on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Theme;

@protocol AddThemeViewDelegate <NSObject>

- (void)duplicateTheme;
- (void)createThemeFromTemplate:(NSString*)name;

@end

@interface AddThemeView : NSView {
	IBOutlet NSButton* _duplicateButton;
	
	NSMutableArray* _templateButtons;
	
	IBOutlet id<AddThemeViewDelegate> _delegate;
}

- (IBAction)buttonAction:(NSButton*)sender;

@property (nonatomic, readonly) NSButton* duplicateButton;

@end
