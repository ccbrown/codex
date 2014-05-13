//
//  Preferences.h
//  CodeX
//
//  Created by Christopher Brown on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSPreferences.h"
#import "Theme.h"

@interface Preferences : NSPreferences {
	// general
	BOOL _restoreWindows;
	BOOL _openNewDocument;
	BOOL _showDocumentShortcuts;
	BOOL _showStatusBar;
	BOOL _autoSavesInPlace;
	NSUInteger _maxRecentDocuments;
	
	// fonts and colors
	Theme* _theme;
	NSMutableArray* _themes;

	// editing
	BOOL _tabKeyInsertsSpaces;
	NSUInteger _tabSize;
	NSString* _tabString;

	NSStringEncoding _defaultEncoding;
	NSString* _defaultLineEnding;
	
	BOOL _wrapLinesByDefault;
	BOOL _showLineNumbers;
	BOOL _autoIndentNewLines;
	BOOL _autoIndentCloseBraces;
	
	// syntax definitions
	NSMutableArray* _syntaxDefinitions;
}

- (void)close;

- (void)sendUpdates;

- (void)restoreUserDefaults;

- (void)saveUserDefaults;

+ (Preferences*)sharedPreferences;

// general
@property (nonatomic, readwrite) BOOL restoreWindows;
@property (nonatomic, readwrite) BOOL openNewDocument;
@property (nonatomic, readwrite) BOOL showDocumentShortcuts;
@property (nonatomic, readwrite) BOOL showStatusBar;
@property (nonatomic, readwrite) BOOL autoSavesInPlace;
@property (nonatomic, readwrite) NSUInteger maxRecentDocuments;

// fonts and colors
@property (nonatomic, retain)   Theme* theme;
@property (nonatomic, readonly) NSMutableArray* themes;

// editing
@property (nonatomic, readwrite) BOOL tabKeyInsertsSpaces;
@property (nonatomic, readwrite) NSUInteger tabSize;
@property (nonatomic, readonly)  NSString* tabString;

@property (nonatomic, readwrite) NSStringEncoding defaultEncoding;
@property (nonatomic, copy)      NSString* defaultLineEnding;

@property (nonatomic, readwrite) BOOL wrapLinesByDefault;
@property (nonatomic, readwrite) BOOL showLineNumbers;
@property (nonatomic, readwrite) BOOL autoIndentNewLines;
@property (nonatomic, readwrite) BOOL autoIndentCloseBraces;

// syntax definitions
@property (nonatomic, readonly) NSMutableArray* syntaxDefinitions;

@end
