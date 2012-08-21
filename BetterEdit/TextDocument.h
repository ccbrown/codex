//
//  TextDocument.h
//  BetterEdit
//
//  Created by Christopher Brown on 11/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EditingTextView.h"

@interface NSDocument (Undocumented)

- (void)_updateWindowControllersWithIsEdited:(BOOL)edited;
- (void)_updateDocumentEditedAndAnimate:(BOOL)edited;

@end

@class TextRulerView, TextProcessor;

@interface TextDocument : NSDocument <NSCoding, NSTextStorageDelegate, EditingTextViewDelegate> {
	NSView* _documentView;
	
	NSScrollView* _scrollView;

	TextRulerView* _rulerView;
	
	EditingTextView* _textView;
	
	NSError* _error;

	KeyThroughTextView* _errorTextView;
	
	TextProcessor* _textProcessor;
	
	NSString* _lineEnding;
	
	NSStringEncoding _encoding;
	
	BOOL _wrapsLines;
}

- (void)updateView;

- (void)reloadPreferences;

- (void)convertLineEndings;

- (BOOL)convertToEncoding:(NSStringEncoding)encoding;
- (BOOL)reloadWithEncoding:(NSStringEncoding)encoding;

@property (readonly) NSView* documentView;
@property (readonly) EditingTextView* textView;
@property (nonatomic, retain) NSError* error;

@property (readwrite, copy) NSString* lineEnding;
@property (readwrite, readwrite) NSStringEncoding encoding;
@property (readwrite, readwrite) BOOL wrapsLines;

@property (nonatomic, retain) TextProcessor* textProcessor;

@end
