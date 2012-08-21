//
//  EditingTextView.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EditingTextView.h"
#import "FontAndColorPreferences.h"

@implementation EditingTextView

- (void)didChangeText {
	[self hideFindMatches];
	[super didChangeText];
}

- (void)keyDown:(NSEvent*)event {
	if (!self.delegate || ![self.delegate respondsToSelector:@selector(textView:doKeyDownByEvent:)] || ![(id<EditingTextViewDelegate>)self.delegate textView:self doKeyDownByEvent:event]) {
		if (![self window] || ![[self window] respondsToSelector:@selector(textView:doKeyDownByEvent:)] || ![(id<EditingTextViewDelegate>)[self window] textView:self doKeyDownByEvent:event]) {
			[super keyDown:event];
		}
	}
}

- (void)hideFindMatches {
	[[self layoutManager] removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, [[self string] length])];
}

- (void)showFindMatchesForRanges:(NSArray*)ranges {
	[self hideFindMatches];
	
	for (NSValue* value in ranges) {
		NSRange range = [value rangeValue];
		[[self layoutManager] addTemporaryAttribute:NSBackgroundColorAttributeName value:[NSColor colorWithDeviceRed:0.7 green:0.7 blue:0.0 alpha:0.5] forCharacterRange:range];
	}
}

- (void)performAdvancedFindPanelAction:(id)sender {
	[[AdvancedFindPanel sharedAdvancedFindPanel] performAction:[sender tag]];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
	if ([item action] == @selector(performAdvancedFindPanelAction:)) {
		return [[AdvancedFindPanel sharedAdvancedFindPanel] validateAction:[item tag]];
	} else {
		return [super validateUserInterfaceItem:item];
	}
}

- (BOOL)becomeFirstResponder {
	if ([super becomeFirstResponder]) {
		[AdvancedFindPanel sharedAdvancedFindPanel].client = self;
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)resignFirstResponder {
	if ([super resignFirstResponder]) {
		if ([AdvancedFindPanel sharedAdvancedFindPanel].client == self) {
			[AdvancedFindPanel sharedAdvancedFindPanel].client = nil;
		}
		return YES;
	} else {
		return NO;
	}
}

- (void)aBEToggleComment:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(textView:doCommandBySelector:)]) {
		[self.delegate textView:self doCommandBySelector:@selector(toggleComment:)];
	}
}

- (void)aBEShiftLeft:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(textView:doCommandBySelector:)]) {
		[self.delegate textView:self doCommandBySelector:@selector(shiftLeft:)];
	}
}

- (void)aBEShiftRight:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(textView:doCommandBySelector:)]) {
		[self.delegate textView:self doCommandBySelector:@selector(shiftRight:)];
	}
}

- (BOOL)isOpaque {
	return NO;
}

- (void)changeFont:(id)sender {
	[self display];
	[[FontAndColorPreferences sharedInstance] changeFont:sender];
	[self display];
}

@end