//
//  SyntaxDefinition.h
//  CodeX
//
//  Created by Christopher Brown on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyntaxDefinition : NSObject <NSCopying, NSCoding> {
	NSString* _name;

	NSString* _processorClassName;
	
	NSArray* _keywords;

	NSArray* _extensions;
}

+ (NSArray*)templateNames;
+ (NSArray*)processorClassNames;

- (id)initFromTemplate:(NSString*)template;

@property (nonatomic, copy) NSString* name;

@property (nonatomic, copy) NSString* processorClassName;

@property (nonatomic, retain) NSArray* keywords;

@property (nonatomic, retain) NSArray* extensions;

@end
