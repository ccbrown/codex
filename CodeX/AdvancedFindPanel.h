//
//  AdvancedFindPanel.h
//  CodeX
//
//  Created by Christopher Brown on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AdvancedFindPanel;

@protocol AdvancedTextFinderClient <NSObject, NSUserInterfaceValidations>

- (NSString*)string;

- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)range;

- (void)hideFindMatches;
- (void)showFindMatchesForRanges:(NSArray*)ranges;
- (void)showFindIndicatorForRange:(NSRange)range;

- (BOOL)shouldChangeTextInRanges:(NSArray*)affectedRanges replacementStrings:(NSArray*)replacementStrings;
- (void)replaceCharactersInRange:(NSRange)range withString:(NSString*)string;
- (void)didChangeText;

- (void)scrollRangeToVisible:(NSRange)range;

@end

@interface AdvancedFindPanel : NSPanel <NSComboBoxDelegate, NSComboBoxDataSource, NSWindowRestoration> {
	id<AdvancedTextFinderClient> _client;
	NSMutableArray* _matchRanges;
	NSUInteger _matchesStringHash;
	
	NSMutableArray* _findHistory;
	NSMutableArray* _replaceHistory;
	
	IBOutlet NSComboBox* _findComboBox;
	IBOutlet NSComboBox* _replaceComboBox;
	
	IBOutlet NSButton* _replaceButton;
	IBOutlet NSButton* _replaceAndFindButton;
	IBOutlet NSButton* _replaceAllButton;
	IBOutlet NSButton* _nextButton;
	IBOutlet NSButton* _previousButton;
	
	IBOutlet NSTextField* _statusField;
	
	IBOutlet NSPopUpButton* _typePopUpButton;

	IBOutlet NSButton* _ignoreCaseButton;
	IBOutlet NSButton* _wrapAroundButton;
}

+ (AdvancedFindPanel*)sharedAdvancedFindPanel;

- (IBAction)advancedFindInputAction:(id)sender;

- (void)invalidateMatchRanges;

- (void)performAction:(NSTextFinderAction)action;
- (BOOL)validateAction:(NSTextFinderAction)action;

@property (nonatomic, retain) id<AdvancedTextFinderClient> client;
@property (nonatomic, readonly) NSArray* matchRanges;

@end
