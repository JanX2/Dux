//
//  DuxCSSAtRuleElement.m
//  Dux
//
//  Created by Abhi Beckert on 2013-4-27.
//
//

#import "DuxCSSAtRuleElement.h"
#import "DuxCSSLanguage.h"

@implementation DuxCSSAtRuleElement

static NSCharacterSet *nextElementCharacterSet;
static NSColor *color;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwrxyzABCDEFGHIJKLMNOPQRSTUVWRXYZ_"] invertedSet];
  
  color = [NSColor colorWithCalibratedRed:0.784 green:0.157 blue:0.161 alpha:1.000];
}

- (id)init
{
  return [self initWithLanguage:[DuxCSSLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  // find next character
  NSUInteger searchStart = startingAt + 1;
  NSRange foundRange = [string.string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStart, string.string.length - searchStart)];
  
  // not found, or the last character in the string?
  if (foundRange.location == NSNotFound || foundRange.location == (string.string.length - 1))
    return string.string.length - startingAt;
  
  return foundRange.location - startingAt;
}

- (NSColor *)color
{
  return color;
}

@end
