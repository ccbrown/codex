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
	NSArray* _keywords;
	
	NSString* _singleLineCommentPrefix;

	NSUInteger _lastHash;
	
	NSMutableArray* _resumePoints;
	
	NSUInteger _highlightResumeIndex;
	NSUInteger _highlightNextHighlight;
	NSUInteger _highlightGoThrough;
}

+ (TextProcessor*)defaultProcessor;
+ (TextProcessor*)processorForExtension:(NSString*)extension;

- (BOOL)isSimilarTo:(TextProcessor*)processor;

- (NSUInteger)quoteLength:(NSString*)string range:(NSRange)range;
- (NSUInteger)whiteSpaceLength:(NSString*)string;

- (void)addPrefix:(NSString*)prefix toSelectedLinesInTextView:(NSTextView*)textView;
- (BOOL)removePrefix:(NSString*)prefix fromSelectedLinesInTextView:(NSTextView*)textView;

- (BOOL)document:(TextDocument*)document textView:(NSTextView*)textView doCommandBySelector:(SEL)selector;
- (BOOL)document:(TextDocument *)document textView:(NSTextView *)textView doKeyDownByEvent:(NSEvent *)event;
- (void)document:(TextDocument*)document textView:(NSTextView*)textView didChangeSelection:(NSRange)oldSelection;

// overload this for syntax highlighting
- (void)syntaxHighlightTextStorage:(NSTextStorage*)textStorage startingAt:(NSUInteger)position;

// call these from syntaxHighlightTextStorage:
- (void)colorText:(NSColor*)color atRange:(NSRange)range textStorage:(NSTextStorage*)textStorage;
- (BOOL)addResumePoint:(NSUInteger)position; // stop highlighting when this returns false

// call these when text changes change
- (void)resetTextStorage:(NSTextStorage*)textStorage;
- (void)replacedCharactersInRange:(NSRange)range newRangeLength:(NSUInteger)newRangeLength textStorage:(NSTextStorage*)textStorage;

@property (nonatomic, retain) NSArray* keywords;
@property (nonatomic, copy) NSString* singleLineCommentPrefix;
@property (nonatomic, retain) NSMutableArray* resumePoints;

@end
