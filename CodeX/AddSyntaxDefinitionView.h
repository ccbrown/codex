//
//  AddSyntaxDefinitionView.h
//  CodeX
//
//  Created by Christopher Brown on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SyntaxDefinition;

@protocol AddSyntaxDefinitionViewDelegate <NSObject>

- (BOOL)shouldEnableDuplicateButton;
- (void)duplicateDefinition;
- (void)createDefinitionFromTemplate:(NSString*)name;

@end

@interface AddSyntaxDefinitionView : NSView <NSPopoverDelegate> {
	IBOutlet NSButton* _duplicateButton;
	
	NSMutableArray* _templateButtons;
	
	IBOutlet id<AddSyntaxDefinitionViewDelegate> _delegate;
}

- (IBAction)buttonAction:(NSButton*)sender;

@property (nonatomic, readonly) NSButton* duplicateButton;

@end
