//  DuxJavaScriptLanguage.h
//  Dux
//
//  Created by Chen Hongzhi on 6/21/12.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxJSONKeyElement.h"
#import "DuxJSONLanguage.h"

static NSCharacterSet *nextElementCharacterSet;
static NSColor *color;

@implementation DuxJSONKeyElement

+ (void)initialize
{
  if (self == [DuxJSONKeyElement class]) {
    nextElementCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\\"];
    color = [NSColor colorWithCalibratedRed:0.557 green:0.031 blue:0.329 alpha:1];
  }
}

- (id)init
{
  return [self initWithLanguage:[DuxJSONLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  BOOL keepLooking = YES;
  NSUInteger searchStartLocation = startingAt + 1;
  NSRange foundRange;
  unichar characterFound;
  
  while (keepLooking) {
    foundRange = [string.string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.length - searchStartLocation)];
    
    if (foundRange.location == NSNotFound || foundRange.location == (string.length - 1))
      return string.length - startingAt;
    
    characterFound = [string.string characterAtIndex:foundRange.location];
    if (characterFound == '\\') {
      searchStartLocation = foundRange.location + 2;
      continue;
    }
    
    keepLooking = NO;
  }
  
  return (foundRange.location + 1) - startingAt;
}

- (NSColor *)color
{
  return color;
}

@end
