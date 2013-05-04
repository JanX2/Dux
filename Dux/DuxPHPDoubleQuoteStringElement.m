//
//  DuxPHPDoubleQuoteStringElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-16.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPHPDoubleQuoteStringElement.h"
#import "DuxPHPLanguage.h"

@implementation DuxPHPDoubleQuoteStringElement

static NSCharacterSet *nextElementCharacterSet;
static NSCharacterSet *validVariableCharacterSet;
static DuxPHPVariableElement *variableElement;
static NSColor *color;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\\$"];
  validVariableCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwrxyzABCDEFGHIJKLMNOPQRSTUVWRXYZ_"];
  
  variableElement = [DuxPHPVariableElement sharedInstance];
  
  color = [NSColor colorWithCalibratedRed:0.76 green:0.1 blue:0.08 alpha:1];
}

- (id)init
{
  return [self initWithLanguage:[DuxPHPLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSString *)string startingAt:(NSUInteger)startingAt didJustPop:(BOOL)didJustPop nextElement:(DuxLanguageElement *__strong*)nextElement
{
  BOOL keepLooking = YES;
  NSUInteger searchStartLocation = startingAt;
  NSRange foundRange;
  unichar characterFound;
  while (keepLooking) {
    // find next character
    foundRange = [string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.length - searchStartLocation)];
    
    // not found, or the last character in the string?
    if (foundRange.location == NSNotFound || foundRange.location == (string.length - 1))
      return string.length - startingAt;
    
    // because the start/end characters are the same, so we need to make sure we didn't just find the first character
    if (foundRange.location == startingAt) {
      if (!didJustPop) {
        searchStartLocation++;
        continue;
      }
    }
    
    // backslash? keep searching
    characterFound = [string characterAtIndex:foundRange.location];
    if (characterFound == '\\') {
      searchStartLocation = foundRange.location + 2;
      continue;
    }
    
    // variable? make sure next char is alphanumeric
    if (characterFound == '$' && string.length > foundRange.location + 1 && ![validVariableCharacterSet characterIsMember:[string characterAtIndex:foundRange.location + 1]]) {
      searchStartLocation = foundRange.location + 1;
      continue;
    }
    
    // stop looking
    keepLooking = NO;
  }
  
  // what's next?
  switch (characterFound) {
    case '"':
      return (foundRange.location + 1) - startingAt;
    case '$':
      *nextElement = variableElement;
      return foundRange.location - startingAt;
  }

  
  // should never reach this, but add this line anyway to make the compiler happy
  return string.length - startingAt;
}

- (NSColor *)color
{
  return color;
}

@end
