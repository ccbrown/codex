//
//  SyntaxDefinition.m
//  BetterEdit
//
//  Created by Christopher Brown on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SyntaxDefinition.h"

@implementation SyntaxDefinition

@synthesize name = _name, processorClassName = _processorClassName, keywords = _keywords, extensions = _extensions;

+ (NSArray*)templateNames {
	return [NSArray arrayWithObjects:@"C++", @"CSS", @"Java", @"PHP", @"Python", @"Scala", @"Shell", @"XML", nil];
}

+ (NSArray*)processorClassNames {
	return [NSArray arrayWithObjects:@"TextProcessor", @"CProcessor", @"CSSProcessor", @"PHPProcessor", @"ShellProcessor", @"XMLProcessor", nil];
}

- (id)initFromTemplate:(NSString*)template {
	if (![[SyntaxDefinition templateNames] containsObject:template]) {
		[self release];
		return nil;
	}
	
	if (self = [super init]) {
		self.name = template;

		if ([template compare:@"C++"] == NSOrderedSame) {
			self.processorClassName = @"CProcessor";
		
			self.keywords = [NSArray arrayWithObjects:
							 @"and", @"and_eq", @"alignas", @"alignof", @"asm", @"auto", @"bitand", @"bitor", @"bool", 
							 @"break", @"case", @"catch", @"char", @"char16_t", @"char32_t", @"class", @"compl", @"const", 
							 @"constexpr", @"const_cast", @"continue", @"decltype", @"default", @"delete", @"double", 
							 @"do", @"dynamic_cast", @"else", @"enum", @"explicit", @"export", @"extern", @"false", @"final", 
							 @"float", @"for", @"friend", @"goto", @"if", @"inline", @"int", @"long", @"mutable", 
							 @"namespace", @"new", @"noexcept", @"not", @"not_eq", @"nullptr", @"operator", @"or", 
							 @"or_eq", @"override", @"private", @"protected", @"public", @"register", @"reinterpret_cast", 
							 @"return", @"short", @"signed", @"sizeof", @"static", @"static_assert", @"static_cast", 
							 @"struct", @"switch", @"template", @"this", @"thread_local", @"throw", @"true", @"try", 
							 @"typedef", @"typeid", @"typename", @"union", @"unsigned", @"using", @"virtual", @"void", 
							 @"volatile", @"wchar_t", @"while", @"xor", @"xor_eq",
							 nil];
			
			self.extensions = [NSArray arrayWithObjects:@"h", @"hh", @"hpp", @"c", @"cc", @"cpp", @"m", @"mm", @"tcc", @"cl", @"vsh", @"fsh", @"gsh", @"idc", nil];
		} else if ([template compare:@"CSS"] == NSOrderedSame) {
			self.processorClassName = @"CSSProcessor";
			
			self.keywords = [NSArray arrayWithObjects: nil];
			
			self.extensions = [NSArray arrayWithObjects:@"css", nil];
		} else if ([template compare:@"Java"] == NSOrderedSame) {
			self.processorClassName = @"CProcessor";
			
			self.keywords = [NSArray arrayWithObjects:
							 @"abstract", @"continue", @"for", @"new", @"switch",
							 @"assert", @"default", @"goto", @"package", @"synchronized",
							 @"boolean", @"do", @"if", @"private", @"this",
							 @"break", @"double", @"implements", @"protected", @"throw",
							 @"byte", @"else", @"import", @"public", @"throws",
							 @"case", @"enum", @"instanceof", @"return", @"transient",
							 @"catch", @"extends", @"int", @"short", @"try",
							 @"char", @"final", @"interface", @"static", @"void",
							 @"class", @"finally", @"long", @"strictfp", @"volatile",
							 @"const", @"float", @"native", @"super", @"while", @"true", 
							 @"false", @"null",
							 nil];
			
			self.extensions = [NSArray arrayWithObjects:@"java", @"jad", nil];
		} else if ([template compare:@"PHP"] == NSOrderedSame) {
			self.processorClassName = @"PHPProcessor";
			
			self.keywords = [NSArray arrayWithObjects:
							 @"abstract", @"and", @"array", @"as", @"break", @"case", @"catch", @"cfunction", @"class", 
							 @"clone", @"const", @"continue", @"declare", @"default", @"do", @"else", @"elseif", 
							 @"enddeclare", @"endfor", @"endforeach", @"endif", @"endswitch", @"endwhile", @"extends", 
							 @"final", @"for", @"foreach", @"function", @"global", @"goto", @"if", @"implements", 
							 @"interface", @"instanceof", @"namespace", @"new", @"old_function", @"or", @"private", 
							 @"protected", @"public", @"static", @"switch", @"throw", @"try", @"use", @"var", @"while", 
							 @"xor", @"__CLASS__", @"__DIR__", @"__FILE__", @"__LINE__", @"__FUNCTION__", @"__METHOD__", 
							 @"__NAMESPACE__", @"die", @"echo", @"empty", @"exit", @"eval", @"include", @"include_once", 
							 @"isset", @"list", @"require", @"require_once", @"return", @"print", @"unset", 
							 @"__halt_compiler", @"php", 
							 nil];
			
			self.extensions = [NSArray arrayWithObjects:@"php", @"php3", @"php4", @"php5", @"phps", @"phtml", nil];
		} else if ([template compare:@"Python"] == NSOrderedSame) {
			self.processorClassName = @"ShellProcessor";
			
			self.keywords = [NSArray arrayWithObjects:
							 @"and", @"assert", @"break", @"class", @"continue", @"def", @"del", @"elif", @"else", @"except", 
							 @"exec", @"finally", @"for", @"from", @"global", @"if", @"import", @"in", @"is", @"lambda", 
							 @"not", @"or", @"pass", @"print", @"raise", @"return", @"try", @"while",
							 nil];
			
			self.extensions = [NSArray arrayWithObjects:@"py", nil];
		} else if ([template compare:@"Scala"] == NSOrderedSame) {
			self.processorClassName = @"CProcessor";
			
			self.keywords = [NSArray arrayWithObjects:
							 @"abstract", @"case", @"catch", @"class", @"def", @"do", @"else",
							 @"extends", @"false", @"final", @"finally", @"for", @"forSome", 
							 @"if", @"implicit", @"import", @"lazy", @"match", @"new", @"null",
							 @"object", @"override", @"package", @"private", @"protected", 
							 @"requires", @"return", @"sealed", @"super", @"this", @"throw", 
							 @"trait", @"try", @"true", @"type", @"val", @"var", @"while", 
							 @"with", @"yield", @"_",
							 nil];
			
			self.extensions = [NSArray arrayWithObjects:@"scala", nil];
		} else if ([template compare:@"Shell"] == NSOrderedSame) {
			self.processorClassName = @"ShellProcessor";
			
			self.keywords = [NSArray arrayWithObjects:
							 @"case", @"do", @"done", @"elif", @"else", @"esac", @"fi", @"for",
							 @"if", @"in", @"then", @"until", @"while",
							 nil];
			
			self.extensions = [NSArray arrayWithObjects:@"sh", nil];
		} else if ([template compare:@"XML"] == NSOrderedSame) {
			self.processorClassName = @"XMLProcessor";
			
			self.keywords = [NSArray arrayWithObjects: nil];
			
			self.extensions = [NSArray arrayWithObjects:@"xml", @"xsd", @"htm", @"html", @"shtml", @"plist", nil];
		}
	}

	return self;
}

- (SyntaxDefinition*)copyWithZone:(NSZone*)zone {
	SyntaxDefinition* copy = [SyntaxDefinition new];
	
	copy.name = self.name;
	
	copy.processorClassName = self.processorClassName;
	
	copy.extensions = self.extensions;
	
	copy.keywords = self.keywords;
	
	return copy;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		self.name = [decoder decodeObjectForKey:@"name"];
		
		self.processorClassName = [decoder decodeObjectForKey:@"processorClassName"];
		
		if (![[SyntaxDefinition processorClassNames] containsObject:self.processorClassName]) {
			[self release];
			return nil;
		}

		self.extensions = [decoder decodeObjectForKey:@"extensions"];
		
		self.keywords = [decoder decodeObjectForKey:@"keywords"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:self.name forKey:@"name"];

	[encoder encodeObject:self.processorClassName forKey:@"processorClassName"];
	
	[encoder encodeObject:self.extensions forKey:@"extensions"];

	[encoder encodeObject:self.keywords forKey:@"keywords"];
}

- (void)dealloc {
	self.name = nil;

	self.processorClassName = nil;
	
	self.keywords = nil;
	
	self.extensions = nil;

	[super dealloc];
}

@end
