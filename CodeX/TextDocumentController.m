//
//  TextDocumentController.m
//  CodeX
//
//  Created by Christopher Brown on 11/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeXAppDelegate.h"
#import "TextDocumentController.h"
#import "TextDocument.h"
#import "Preferences.h"

@implementation TextDocumentController

- (id)init {
    if (self = [super init]) {
        // Initialization code here.
    }

    return self;
}

- (Class)documentClassForType:(NSString*)documentTypeName {
	if ([documentTypeName isEqualToString:@"All Documents"]) {
		return [TextDocument class];
	}
	return nil;
}

// this isn't used right now, but is here in case Apple decides to expose this method
- (void)closeAllDocumentsWithDelegate:(id)delegate shouldTerminateSelector:(SEL)selector {
	[self _closeAllDocumentsWithDelegate:delegate shouldTerminateSelector:selector];
}

- (void)_closeAllDocumentsWithDelegate:(id)delegate shouldTerminateSelector:(SEL)selector {
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[delegate methodSignatureForSelector:selector]];
	
	NSDocumentController* arg2 = self;
	BOOL arg3 = YES;
	
	[invocation setSelector:selector];
	[invocation setArgument:&arg2 atIndex:2];
	[invocation setArgument:&arg3 atIndex:3];
	[invocation invokeWithTarget:delegate];
}

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)extensions {
	return [super runModalOpenPanel:openPanel forTypes:[NSArray arrayWithObject:@"*"]];
}

- (void)reopenDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *, BOOL, NSError *))completionHandler {
	// do nothing
}

- (NSUInteger)maximumRecentDocumentCount {
	return [Preferences sharedPreferences].maxRecentDocuments;
}

+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler {
	completionHandler((NSWindow*)[(CodeXAppDelegate*)[NSApp delegate] restoreWindowWithState:state], nil);
}

@end
