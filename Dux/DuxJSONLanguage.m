//  DuxJavaScriptLanguage.h
//  Dux
//
//  Created by Chen Hongzhi on 6/21/12.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxJSONLanguage.h"
#import "DuxJSONBaseElement.h"

static NSRegularExpression *keywordsExpression;
static NSIndexSet *keywordIndexSet = nil;

@implementation DuxJSONLanguage

+ (void)load
{
  [DuxLanguage registerLanguage:[self class]];
}

- (DuxLanguageElement *)baseElement
{
  return [DuxJSONBaseElement sharedInstance];
}

+ (NSIndexSet *)keywordIndexSet
{
  return keywordIndexSet;
}

- (void)prepareToParseTextStorage:(NSTextStorage *)textStorage
{
  [super prepareToParseTextStorage:textStorage];
  
  if (!keywordsExpression) {
    NSArray *keywords = [[NSArray alloc] initWithObjects:@"true", @"false", @"null", nil];
    keywordsExpression = [[NSRegularExpression alloc] initWithPattern:[[NSString alloc] initWithFormat:@"\\b(%@)\\b", [keywords componentsJoinedByString:@"|"]] options:0 error:NULL];
  }
  
  NSMutableIndexSet *keywordIndexesMutable = [[NSIndexSet indexSet] mutableCopy];
  [keywordsExpression enumerateMatchesInString:textStorage.string options:0 range:NSMakeRange(0, textStorage.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
    [keywordIndexesMutable addIndexesInRange:match.range];
  }];
  
  keywordIndexSet = [keywordIndexesMutable copy];
}

+ (BOOL)isDefaultLanguageForURL:(NSURL *)URL textContents:(NSString *)textContents
{
  static NSArray *extensions = nil;
  if (!extensions) {
    extensions = [NSArray arrayWithObjects:@"json", nil];
  }
  
  if (URL && [extensions containsObject:[URL pathExtension]])
    return YES;
  
  return NO;
}

@end
