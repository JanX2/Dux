//
//  DuxCSSLanguage.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-20.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxCSSLanguage.h"

@implementation DuxCSSLanguage

+ (void)load
{
  [DuxLanguage registerLanguage:[self class]];
}

- (DuxLanguageElement *)baseElement
{
  return [DuxCSSBaseElement sharedInstance];
}

+ (BOOL)isDefaultLanguageForURL:(NSURL *)URL textContents:(NSString *)textContents
{
  static NSArray *extensions = nil;
  if (!extensions) {
    extensions = @[@"css", @"less"];
  }
  
  if (URL && [extensions containsObject:[URL pathExtension]])
    return YES;
  
  return NO;
}

- (NSArray *)findSymbolsInDocumentContents:(NSString *)string
{
  NSRegularExpression *keywordRegex = [[NSRegularExpression alloc] initWithPattern:@"(.+?)\\s*\n*\\s*\\{" options:NSRegularExpressionCaseInsensitive error:NULL];
  
  NSMutableArray *matches = @[].mutableCopy;
  [keywordRegex enumerateMatchesInString:string options:0 range:NSMakeRange(0, string.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    NSRange range = [match rangeAtIndex:1];
  
    NSString *name = [string substringWithRange:range];
    
    [matches addObject:@{@"range": [NSValue valueWithRange:range], @"name": name}];
  }];
  
  return matches.copy;
}

@end
