//
//  Preferences.m
//  BetterEdit
//
//  Created by Christopher Brown on 11/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"
#import "GeneralPreferences.h"
#import "FontAndColorPreferences.h"
#import "EditingPreferences.h"
#import "SyntaxPreferences.h"
#import "BetterEditAppDelegate.h"
#import "SyntaxDefinition.h"

#include <dlfcn.h>

@implementation Preferences

@synthesize theme = _theme, themes = _themes, tabKeyInsertsSpaces = _tabKeyInsertsSpaces, tabSize = _tabSize, 
tabString = _tabString, restoreWindows = _restoreWindows, openNewDocument = _openNewDocument, showLineNumbers = _showLineNumbers, 
autoIndentNewLines = _autoIndentNewLines, autoIndentCloseBraces = _autoIndentCloseBraces, showDocumentShortcuts = _showDocumentShortcuts,
defaultEncoding = _defaultEncoding, defaultLineEnding = _defaultLineEnding, wrapLinesByDefault = _wrapLinesByDefault, 
showStatusBar = _showStatusBar, autoSavesInPlace = _autoSavesInPlace, maxRecentDocuments = _maxRecentDocuments,
syntaxDefinitions = _syntaxDefinitions;

- (id)init {
	// a call to _nsBeginNSPSupport() must come before [super init]
	
	void* image = dlopen("/System/Library/Frameworks/AppKit.framework/AppKit", RTLD_LAZY | RTLD_LOCAL);
	void (*beginNSPSupport)() = dlsym(image, "_nsBeginNSPSupport");
	dlclose(image);
	
	if (beginNSPSupport) {
		beginNSPSupport(); 
	}
	
    if (self = [super init]) {
		_tabString = nil;
		_themes = [[NSMutableArray alloc] initWithCapacity:1];
		_syntaxDefinitions = [[NSMutableArray alloc] initWithCapacity:1];

	    [self addPreferenceNamed:@"General" owner:[GeneralPreferences sharedInstance]];
		[self addPreferenceNamed:@"Fonts and Colors" owner:[FontAndColorPreferences sharedInstance]];
		[self addPreferenceNamed:@"Editing" owner:[EditingPreferences sharedInstance]];
		[self addPreferenceNamed:@"Syntax Definitions" owner:[SyntaxPreferences sharedInstance]];

		[self restoreUserDefaults];
	}

    return self;
}

- (void)restoreUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	NSInteger v = [defaults integerForKey:@"BEPrefsVersion"];
	// 1 = 1.0
	// 2 = 1.1
	
	// first release
	if (v < 1) {
		// general
		self.restoreWindows        = YES;
		self.openNewDocument       = YES;
		self.showDocumentShortcuts = YES;
		self.showStatusBar         = YES;
		self.autoSavesInPlace      = YES;
		self.maxRecentDocuments    = 20;

		// fonts and colors
		[self.themes removeAllObjects];
		for (NSString* template in [Theme templateNames]) {
			Theme* theme = [[Theme alloc] initFromTemplate:@"Default"];
			[self.themes addObject:theme];
			[theme release];
		}
		self.theme = [self.themes objectAtIndex:0];
		
		// editing
		self.tabKeyInsertsSpaces   = NO;
		self.tabSize               = 4;
		self.defaultEncoding       = NSUTF8StringEncoding;
		self.defaultLineEnding     = @"\n";
		self.wrapLinesByDefault    = NO;
		self.showLineNumbers       = YES;
		self.autoIndentNewLines    = YES;
		self.autoIndentCloseBraces = YES;
		
		// syntax definitions
		[self.syntaxDefinitions removeAllObjects];
		for (NSString* template in [SyntaxDefinition templateNames]) {
			SyntaxDefinition* definition = [[SyntaxDefinition alloc] initFromTemplate:template];
			[self.syntaxDefinitions addObject:definition];
			[definition release];
		}
	} else {
		// general
		self.restoreWindows        = [defaults boolForKey:@"restoreWindows"];
		self.openNewDocument       = [defaults boolForKey:@"openNewDocument"];
		self.showDocumentShortcuts = [defaults boolForKey:@"showDocumentShortcuts"];
		self.showStatusBar         = [defaults boolForKey:@"showStatusBar"];
		self.autoSavesInPlace      = [defaults boolForKey:@"autoSavesInPlace"];
		self.maxRecentDocuments    = [defaults integerForKey:@"maxRecentDocuments"];
		
		// fonts and colors
		[self.themes removeAllObjects];
		[self.themes addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithData:[defaults objectForKey:@"themes"]]];
		if ([self.themes count] > 0) {
			NSInteger t = [defaults integerForKey:@"theme"];
			if (t < [self.themes count]) {
				self.theme = [self.themes objectAtIndex:[defaults integerForKey:@"theme"]];
			} else {
				self.theme = [self.themes objectAtIndex:0];
			}
		} else {
			Theme* theme = [[Theme alloc] initFromTemplate:@"Default"];
			[self.themes addObject:theme];
			self.theme = theme;
			[theme release];
		}
		
		// editing
		self.tabKeyInsertsSpaces   = [defaults boolForKey:@"tabKeyInsertsSpaces"];
		self.tabSize               = [defaults integerForKey:@"tabSize"];
		self.defaultEncoding       = [defaults integerForKey:@"defaultEncoding"];
		self.defaultLineEnding     = [defaults objectForKey:@"defaultLineEnding"];
		self.wrapLinesByDefault    = [defaults boolForKey:@"wrapLinesByDefault"];
		self.showLineNumbers       = [defaults boolForKey:@"showLineNumbers"];
		self.autoIndentNewLines    = [defaults boolForKey:@"autoIndentNewLines"];
		self.autoIndentCloseBraces = [defaults boolForKey:@"autoIndentCloseBraces"];
		
		// syntax definitions
		[self.syntaxDefinitions removeAllObjects];
		[self.syntaxDefinitions addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithData:[defaults objectForKey:@"syntaxDefinitions"]]];
	}

	if (v < 2) {
		SyntaxDefinition* cssDefinition = [[[SyntaxDefinition alloc] initFromTemplate:@"CSS"] autorelease];
		[self.syntaxDefinitions addObject:cssDefinition];

		SyntaxDefinition* phpDefinition = [[[SyntaxDefinition alloc] initFromTemplate:@"PHP"] autorelease];
		[self.syntaxDefinitions addObject:phpDefinition];

		SyntaxDefinition* pythonDefinition = [[[SyntaxDefinition alloc] initFromTemplate:@"Python"] autorelease];
		[self.syntaxDefinitions addObject:pythonDefinition];
	}

	[self saveUserDefaults];
	[defaults setInteger:2 forKey:@"BEPrefsVersion"];
}

- (void)saveUserDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	// general
	[defaults setBool:self.restoreWindows        forKey:@"restoreWindows"];
	[defaults setBool:self.openNewDocument       forKey:@"openNewDocument"];
	[defaults setBool:self.showDocumentShortcuts forKey:@"showDocumentShortcuts"];
	[defaults setBool:self.showStatusBar         forKey:@"showStatusBar"];
	[defaults setBool:self.autoSavesInPlace      forKey:@"autoSavesInPlace"];
	[defaults setInteger:self.maxRecentDocuments forKey:@"maxRecentDocuments"];
	
	// fonts and colors
	[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.themes] forKey:@"themes"];
	[defaults setInteger:[self.themes indexOfObject:self.theme] forKey:@"theme"];

	// editing
	[defaults setBool:self.tabKeyInsertsSpaces forKey:@"tabKeyInsertsSpaces"];
	[defaults setInteger:self.tabSize forKey:@"tabSize"];
	[defaults setInteger:self.defaultEncoding forKey:@"defaultEncoding"];
	[defaults setObject:self.defaultLineEnding forKey:@"defaultLineEnding"];
	[defaults setBool:self.wrapLinesByDefault forKey:@"wrapLinesByDefault"];
	[defaults setBool:self.showLineNumbers forKey:@"showLineNumbers"];
	[defaults setBool:self.autoIndentNewLines forKey:@"autoIndentNewLines"];
	[defaults setBool:self.autoIndentCloseBraces forKey:@"autoIndentCloseBraces"];

	// syntax definitions
	[defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.syntaxDefinitions] forKey:@"syntaxDefinitions"];
}

- (void)updateTabString {
	[_tabString release];
	if (_tabKeyInsertsSpaces && _tabSize <= 100) {
		char* string = (char*)malloc(_tabSize + 1);
		memset(string, ' ', _tabSize);
		string[_tabSize] = '\0';
		_tabString = [[NSString alloc] initWithBytesNoCopy:string length:_tabSize encoding:NSUTF8StringEncoding freeWhenDone:YES];
	} else {
		_tabString = @"\t";
	}
}

- (void)setTabSize:(NSUInteger)tabSize {
	_tabSize = tabSize;
	
	[self updateTabString];
}

- (void)setTabKeyInsertsSpaces:(BOOL)tabKeyInsertsSpaces {
	_tabKeyInsertsSpaces = tabKeyInsertsSpaces;

	[self updateTabString];
}

- (BOOL)windowShouldClose:(id)arg1 {
	[self saveUserDefaults];
	[[NSColorPanel sharedColorPanel] close];
	[[NSFontPanel sharedFontPanel] close];
	
	return [super windowShouldClose:arg1];
}

- (void)close {
	[self saveUserDefaults];

	[_preferencesPanel close];
}

- (void)sendUpdates {
	[kBetterEditAppDelegate reloadPreferences];
}

- (BOOL)usesButtons {
    return NO;
}

- (void)dealloc {
	[self saveUserDefaults];
	
	self.theme = nil;
	[_themes release];
	[_tabString release];
	[_syntaxDefinitions release];
	
	[super dealloc];
}

+ (Preferences*)sharedPreferences {
	return [super sharedPreferences];
}

@end
