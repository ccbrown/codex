//
//  TextProcessor.h
//  BetterEdit
//
//  Created by Christopher Brown on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TextDocument;

@interface TextProcessor : NSObject {
	NSUInteger _hash;

	NSArray* _keywords;
	
	NSString* _singleLineCommentPrefix;
}

+ (TextProcessor*)defaultProcessor;
+ (TextProcessor*)processorForExtension:(NSString*)extension;

- (BOOL)isSimilarTo:(TextProcessor*)processor;

- (NSUInteger)quoteLength:(NSString*)string range:(NSRange)range;
- (NSUInteger)whiteSpaceLength:(NSString*)string;

- (void)addPrefix:(NSString*)prefix toSelectedLinesInTextView:(NSTextView*)textView;
- (BOOL)removePrefix:(NSString*)prefix fromSelectedLinesInTextView:(NSTextView*)textView;

- (void)formatTextStorage:(NSTextStorage*)textStorage;
- (void)formatTextStorage:(NSTextStorage*)textStorage range:(NSRange)range;

- (BOOL)document:(TextDocument*)document textView:(NSTextView*)textView doCommandBySelector:(SEL)selector;
- (BOOL)document:(TextDocument *)document textView:(NSTextView *)textView doKeyDownByEvent:(NSEvent *)event;
- (void)document:(TextDocument*)document textView:(NSTextView*)textView didChangeSelection:(NSRange)oldSelection;

- (void)invalidateHash;

- (BOOL)prepareToProcessText:(NSTextStorage*)text;

@property (nonatomic, retain) NSArray* keywords;

@property (nonatomic, copy) NSString* singleLineCommentPrefix;

@end
