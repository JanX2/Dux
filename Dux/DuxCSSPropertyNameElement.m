//
//  DuxCSSPropertyNameElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-20.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxCSSPropertyNameElement.h"
#import "DuxCSSLanguage.h"

@implementation DuxCSSPropertyNameElement

static NSCharacterSet *nextElementCharacterSet;
static NSColor *color;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"-0123456789abcdefghijklmnopqrstuvwrxyzABCDEFGHIJKLMNOPQRSTUVWRXYZ"] invertedSet];
  
  color = [NSColor colorWithCalibratedRed:0.216 green:0.349 blue:0.365 alpha:1.000];
}

- (id)init
{
  return [self initWithLanguage:[DuxCSSLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSString *)string startingAt:(NSUInteger)startingAt didJustPop:(BOOL)didJustPop nextElement:(DuxLanguageElement *__strong*)nextElement
{
  // find next character
  NSRange foundRange = [string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(startingAt, string.length - startingAt)];
  
  // not found, or the last character in the string?
  if (foundRange.location == NSNotFound || foundRange.location == (string.length - 1))
    return string.length - startingAt;
  
  return foundRange.location - startingAt;
}

- (NSColor *)color
{
  return color;
}

@end
