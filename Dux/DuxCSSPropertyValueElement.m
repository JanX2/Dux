//
//  DuxCSSPropertyValueElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-20.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxCSSPropertyValueElement.h"
#import "DuxCSSLanguage.h"

@implementation DuxCSSPropertyValueElement

static NSCharacterSet *nextElementCharacterSet;
static NSCharacterSet *numericCharacterSet;

static DuxCSSCommentElement *commentElement;
static DuxCSSNumberValueElement *numberValueElement;
static DuxCSSColorValueElement *colorValueElement;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"/;#-0123456789}\n"];
  numericCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
  
  commentElement = [DuxCSSCommentElement sharedInstance];
  numberValueElement = [DuxCSSNumberValueElement sharedInstance];
  colorValueElement = [DuxCSSColorValueElement sharedInstance];
}

- (id)init
{
  return [self initWithLanguage:[DuxCSSLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSString *)string startingAt:(NSUInteger)startingAt didJustPop:(BOOL)didJustPop nextElement:(DuxLanguageElement *__strong*)nextElement
{
  // scan up to the next character
  BOOL keepLooking = YES;
  NSUInteger searchStartLocation = startingAt;
  NSRange foundCharacterSetRange;
  unichar characterFound;
  while (keepLooking) {
    foundCharacterSetRange = [string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.length - searchStartLocation)];
    
    if (foundCharacterSetRange.location == NSNotFound)
      break;
    
    // did we find a / character? check if it's a comment or not
    characterFound = [string characterAtIndex:foundCharacterSetRange.location];
    if (string.length > (foundCharacterSetRange.location + 1) && characterFound == '/') {
      characterFound = [string characterAtIndex:foundCharacterSetRange.location + 1];
      if (characterFound != '*') {
        searchStartLocation++;
        continue;
      }
    }
    
    // did we find a - character? check if it's followed by a digit
    if (string.length > (foundCharacterSetRange.location + 1) && characterFound == '-') {
      characterFound = [string characterAtIndex:foundCharacterSetRange.location + 1];
      if (![numericCharacterSet characterIsMember:characterFound]) {
        searchStartLocation++;
        continue;
      }
    }
    
    keepLooking = NO;
  }  
  // scanned up to the end of the string?
  if (foundCharacterSetRange.location == NSNotFound)
    return string.length - startingAt;
  
  // what character did we find?
  switch (characterFound) {
    case '*':
      *nextElement = commentElement;
      return foundCharacterSetRange.location - startingAt;
    case ';':
    case '}':
    case '\n':
      return foundCharacterSetRange.location - startingAt;
    case '#':
      *nextElement = colorValueElement;
      return foundCharacterSetRange.location - startingAt;
    case '-':
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      *nextElement = numberValueElement;
      return foundCharacterSetRange.location - startingAt;
  }
  
  // should never reach this, but add this line anyway to make the compiler happy
  return string.length - startingAt;
}

@end
