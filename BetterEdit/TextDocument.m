//
//  TextDocument.m
//  BetterEdit
//
//  Created by Christopher Brown on 11/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextRulerView.h"
#import "TextDocument.h"
#import "BetterEditAppDelegate.h"
#import "Preferences.h"

#import "TextProcessor.h"

@implementation TextDocument

@synthesize documentView = _documentView, textView = _textView, error = _error, lineEnding = _lineEnding, encoding = _encoding, wrapsLines = _wrapsLines;

- (id)init {

    if (self = [super init]) {
		self.error = nil;
		_errorTextView = nil;

		self.encoding = [Preferences sharedPreferences].defaultEncoding;
		self.wrapsLines = [Preferences sharedPreferences].wrapLinesByDefault;
		self.lineEnding = [Preferences sharedPreferences].defaultLineEnding;

		_documentView = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 10.0, 10.0)];
		[_documentView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		
		_textView = [[EditingTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 10.0, 10.0)];
		[_textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		[_textView setAllowsUndo:YES];
		[_textView setRichText:NO];
		[_textView setEditable:YES];
		[_textView setUsesFindBar:NO];
		[_textView setUsesFindPanel:YES];
		[_textView setUsesFontPanel:NO];
		[_textView setTextContainerInset:(NSSize){4.0, 4.0}];
		[_textView setDelegate:self];
		[_textView setAutomaticDashSubstitutionEnabled:NO];
		[_textView setAutomaticLinkDetectionEnabled:NO];
		[_textView setAutomaticDataDetectionEnabled:NO];
		[_textView setAutomaticTextReplacementEnabled:NO];
		[_textView setAutomaticQuoteSubstitutionEnabled:NO];
		[_textView setAutomaticSpellingCorrectionEnabled:NO];
		[[_textView textStorage] setDelegate:self];

		_scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 10.0, 10.0)];
		[_scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		[_scrollView setHasHorizontalScroller:YES];
		[_scrollView setHasVerticalScroller:YES];
		[_scrollView setDocumentView:_textView];

		_rulerView = [[TextRulerView alloc] initWithScrollView:_scrollView orientation:NSVerticalRuler];
		
		[_scrollView setVerticalRulerView:_rulerView];
		
		[_textView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

		[_documentView addSubview:_scrollView];

		self.textProcessor = [TextProcessor defaultProcessor];

		[self updateView];
	}
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {	
	if (self = [self init]) {
		[self restoreStateWithCoder:coder];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[self encodeRestorableStateWithCoder:coder];
}

- (void)restoreStateWithCoder:(NSCoder *)coder {
	[super restoreStateWithCoder:coder];

	self.encoding = [coder decodeIntForKey:@"encoding"];
	self.wrapsLines = [coder decodeBoolForKey:@"wrapsLines"];

	NSString* textViewString = [coder decodeObjectForKey:@"textViewString"];
	if (textViewString) {
		[_textView setString:textViewString];
		[self updateChangeCount:NSChangeReadOtherContents];
	}
	[self setFileURL:[coder decodeObjectForKey:@"documentURL"]];
	if ([self fileURL]) {
		NSError* outError;
		if (![self readFromURL:[self fileURL] ofType:@"All Documents" error:&outError]) {
			NSLog(@"File couldn't be read: %@", outError);
			self.error = outError;
		}
	}
	[_textView setSelectedRanges:[coder decodeObjectForKey:@"selectedRanges"]];
	NSRange glyphRange = [[_textView layoutManager] glyphRangeForCharacterRange:[_textView selectedRange] actualCharacterRange:NULL];
	[_textView scrollRectToVisible:[[_textView layoutManager] boundingRectForGlyphRange:glyphRange inTextContainer:[_textView textContainer]]];
	[self setDisplayName:[coder decodeObjectForKey:@"displayName"]];
	self.lineEnding = [coder decodeObjectForKey:@"lineEnding"];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];

	[coder encodeInt:self.encoding forKey:@"encoding"];
	[coder encodeBool:self.wrapsLines forKey:@"wrapsLines"];

	[coder encodeObject:[_textView selectedRanges] forKey:@"selectedRanges"];
	[coder encodeObject:self.lineEnding forKey:@"lineEnding"];
	[coder encodeObject:[self displayName] forKey:@"displayName"];
	if (!self.error && [self isDocumentEdited]) {
		[coder encodeObject:[_textView string] forKey:@"textViewString"];
	}
	[coder encodeObject:[self fileURL] forKey:@"documentURL"];
}

- (void)makeWindowControllers {
	[kBetterEditAppDelegate openTextDocument:self];
}

- (TextProcessor *)textProcessor {
	return _textProcessor;
}

- (void)setTextProcessor:(TextProcessor *)textProcessor {
	if (textProcessor != _textProcessor) {
		[_textProcessor release];
		_textProcessor = [textProcessor retain];
		[_textProcessor resetTextStorage:[_textView textStorage]];
	}
}

// undocumented
- (void)_updateWindowControllersWithIsEdited:(BOOL)edited {
	[super _updateWindowControllersWithIsEdited:edited];
	[kBetterEditAppDelegate documentUpdated:self];
}

// undocumented
- (void)_updateDocumentEditedAndAnimate:(BOOL)edited {
	[super _updateDocumentEditedAndAnimate:edited];
	[kBetterEditAppDelegate documentUpdated:self];
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification {
	NSTextStorage* textStorage = [notification object];
	NSRange range = [textStorage editedRange];
	NSInteger changeInLength = [textStorage changeInLength];

	[_textProcessor replacedCharactersInRange:range newRangeLength:range.length + changeInLength textStorage:textStorage];

	[self invalidateRestorableState];
}

- (void)reloadPreferences {
	TextProcessor* newProcessor = [TextProcessor processorForExtension:[[self fileURL] pathExtension]];
	if (![newProcessor isSimilarTo:self.textProcessor]) {
		self.textProcessor = newProcessor;
	}

	[self.textProcessor resetTextStorage:[_textView textStorage]];

	[self updateView];
}

- (void)convertLineEndings {
	NSString* original = [_textView string];
	
	NSString* noCRLFs = [original stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];

	NSString* noCRs = [noCRLFs stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
	
	NSString* result;
	
	if ([self.lineEnding compare:@"\n"] == NSOrderedSame) {
		result = noCRs;
	} else {
		result = [noCRs stringByReplacingOccurrencesOfString:@"\n" withString:self.lineEnding];
	}
	
	if ([result compare:original] == NSOrderedSame) {
		return;
	}
	
	if ([_textView shouldChangeTextInRange:NSMakeRange(0, original.length) replacementString:result]) {
		[_textView replaceCharactersInRange:NSMakeRange(0, original.length) withString:result];
		[_textView didChangeText];
	}
}

// for the undo manager only
- (void)_convertToEncoding:(NSNumber*)encoding {
	[self convertToEncoding:[encoding unsignedIntegerValue]];
}

- (BOOL)convertToEncoding:(NSStringEncoding)encoding {
	NSString* original = [_textView string];

	NSData* data = [original dataUsingEncoding:encoding allowLossyConversion:NO];

	if (!data) {
		return NO;
	}

	NSString* result = [[NSString alloc] initWithData:data encoding:encoding];
	
	if (!result) {
		return NO;
	}
	
	[[self undoManager] registerUndoWithTarget:self selector:@selector(_convertToEncoding:) object:[NSNumber numberWithUnsignedInteger:_encoding]];
	[[self undoManager] setActionName:@"Encoding"];
	
	self.encoding = encoding;
	
	// don't let the text view register an undo for this
	[[self undoManager] disableUndoRegistration];

	if ([_textView shouldChangeTextInRange:NSMakeRange(0, original.length) replacementString:result]) {
		[_textView replaceCharactersInRange:NSMakeRange(0, original.length) withString:result];
		[_textView didChangeText];
	}

	[[self undoManager] enableUndoRegistration];

	[result release];
	
	return YES;
}

- (BOOL)reloadWithEncoding:(NSStringEncoding)encoding {
	if (!self.fileURL) {
		// just return success for non-files
		return YES;
	}
	
	self.encoding = encoding;
	
	NSError* outError;
	
	if (![self revertToContentsOfURL:self.fileURL ofType:@"All Documents" error:&outError]) {
		NSLog(@"Couldn't reload file: %@", outError);
		self.error = outError;
		return NO;
	}
	
	// if the reload failed, the encoding will be different
	return (self.encoding == encoding);
}

- (void)updateView {
	Preferences* prefs = [Preferences sharedPreferences];

	NSMutableParagraphStyle* paragraphStyle = [[_textView defaultParagraphStyle] mutableCopy];
	if (paragraphStyle == nil) {
		paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	}
	float charWidth = [[prefs.theme.font screenFontWithRenderingMode:NSFontDefaultRenderingMode] advancementForGlyph:' '].width;
	[paragraphStyle setDefaultTabInterval:(charWidth * prefs.tabSize)];
	[paragraphStyle setTabStops:[NSArray array]];
	
	if (self.wrapsLines) {
		[paragraphStyle setLineBreakMode:NSLineBreakByCharWrapping];
		[[_textView textContainer] setContainerSize:NSMakeSize(_scrollView.contentSize.width, FLT_MAX)];
		[[_textView textContainer] setWidthTracksTextView:YES];
		[_textView setFrameSize:[[_textView textContainer] containerSize]];
		[_textView setHorizontallyResizable:NO];
		[_scrollView setHasHorizontalScroller:NO];
	} else {
		[[_textView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		[[_textView textContainer] setWidthTracksTextView:NO];
		[_textView setHorizontallyResizable:YES];
		[_scrollView setHasHorizontalScroller:YES];
	}
	
	[_textView setDefaultParagraphStyle:paragraphStyle];
	
	NSMutableDictionary* typingAttributes = [[_textView typingAttributes] mutableCopy];
	[typingAttributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];	
	[typingAttributes setObject:prefs.theme.font forKey:NSFontAttributeName];
	[_textView setTypingAttributes:typingAttributes];

	[_textView setFont:prefs.theme.font];
	[_textView setBackgroundColor:prefs.theme.backgroundColor];
	[_textView setInsertionPointColor:prefs.theme.cursorColor];

	[_textView setSelectedTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:prefs.theme.selectionColor, NSBackgroundColorAttributeName, nil]];

	[_scrollView setBackgroundColor:prefs.theme.backgroundColor];

	[_scrollView setRulersVisible:prefs.showLineNumbers];
	[_rulerView setNeedsDisplay:YES];

	if (self.error) {
		if (!_errorTextView) {
			_errorTextView = [[KeyThroughTextView alloc] initWithFrame:NSMakeRect(100.0, 200.0, self.documentView.bounds.size.width - 200.0, self.documentView.bounds.size.height - 400.0)];
			[_errorTextView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
			[_errorTextView setString:[self.error description]];
			[_errorTextView setEditable:NO];
			[_errorTextView setSelectable:YES];
			[_errorTextView setBackgroundColor:[NSColor clearColor]];
			
			[_documentView addSubview:_errorTextView];
			[_scrollView removeFromSuperview];
		}
		[_textView setEditable:NO];
	}

	[[_textView textStorage] addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [[_textView textStorage] length])];
	
	// if we don't fix the size here, it'll get drawn when the height is FLT_MAX which does weird things
	[_textView sizeToFit];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	if ([typeName isEqualToString:@"All Documents"]) {
		return [[_textView string] dataUsingEncoding:_encoding];
	}

    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	if ([typeName isEqualToString:@"All Documents"]) {
		NSString* string;
		// try the current encoding, then the default, then iso latin 1
		if ((string = [[NSString alloc] initWithData:data encoding:self.encoding])) {
			// success, do nothing
		} else if ((string = [[NSString alloc] initWithData:data encoding:[Preferences sharedPreferences].defaultEncoding])) {
			self.encoding = [Preferences sharedPreferences].defaultEncoding;
		} else {
			string = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
			self.encoding = NSISOLatin1StringEncoding;
		}
		[_textView setString:string];
		[string release];
		return YES;
	}

    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return NO;
}

- (void)setFileURL:(NSURL*)absoluteURL {
	NSString* extension = [absoluteURL pathExtension];

	if ([extension compare:[[self fileURL] pathExtension]] != NSOrderedSame) {
		self.textProcessor = [TextProcessor processorForExtension:extension];
	}
	
	[super setFileURL:absoluteURL];

	[kBetterEditAppDelegate documentUpdated:self];
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
	if (self.textProcessor) {
		return [self.textProcessor document:self textView:textView doCommandBySelector:selector];
	}

	return NO;
}

- (BOOL)textView:(NSTextView *)textView doKeyDownByEvent:(NSEvent *)event {
	return [self.textProcessor document:self textView:textView doKeyDownByEvent:event];
}

- (NSArray*)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
	return nil;
}

- (void)textViewDidChangeSelection:(NSNotification *)notification {
	NSRange oldSelection = [(NSValue*)[[notification userInfo] objectForKey:@"NSOldSelectedCharacterRange"] rangeValue];
	
	[self.textProcessor document:self textView:_textView didChangeSelection:oldSelection];

	[kBetterEditAppDelegate documentUpdated:self];
}

-(void)textDidChange:(NSNotification *)notification {
	[self invalidateRestorableState];
	[self updateChangeCount:NSChangeDone];
	[_rulerView setNeedsDisplay:YES];

	[kBetterEditAppDelegate documentUpdated:self];
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
	return [NSPrintOperation printOperationWithView:_textView];
}

- (NSString*)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation {
	// required for revert to work right
	if (self.fileURL) {
		return [self.fileURL pathExtension];
	}
	return @"";
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
	if ([item action] == @selector(revertDocumentToSaved:) && [(NSObject*)item isKindOfClass:[NSMenuItem class]]) {
		// why does the revert button get hidden?
		[(NSMenuItem*)item setHidden:NO];
	} else if ([item action] == @selector(saveDocumentAs:)) {
		// enable save as
		return YES;
	}
	return [super validateUserInterfaceItem:item];
}

+ (BOOL)autosavesInPlace {
    return kBetterEditAppDelegate.autoSavesInPlace;
}

+ (BOOL)isNativeType:(NSString*)type {
	return [type isEqualToString:@"All Documents"];
}

+ (NSArray*)readableTypes {
	return [NSArray arrayWithObject:@"All Documents"];
}

+ (NSArray*)writableTypes {
	return [NSArray arrayWithObject:@"All Documents"];
}

- (void)dealloc {	
	self.error = nil;

	[_rulerView release];
	[_scrollView release];
	[_textView release];
	[_errorTextView release];
	[_documentView release];
	
	self.textProcessor = nil;
	self.lineEnding = nil;

	[super dealloc];
}

@end
