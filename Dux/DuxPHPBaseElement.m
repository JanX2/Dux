//
//  DuxPHPBaseElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-16.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPHPBaseElement.h"
#import "DuxPHPLanguage.h"

@implementation DuxPHPBaseElement

static NSCharacterSet *nextElementCharacterSet;
static NSCharacterSet *numericCharacterSet;
static NSCharacterSet *nonNumericCharacterSet;
static NSCharacterSet *alphabeticCharacterSet;
static NSRegularExpression *keywordsExpression;

static DuxPHPSingleQuoteStringElement *singleQuoteStringElement;
static DuxPHPDoubleQuoteStringElement *doubleQuoteStringElement;
static DuxPHPNumberElement *numberElement;
static DuxPHPVariableElement *variableElement;
static DuxPHPKeywordElement *keywordElement;
static DuxPHPSingleLineCommentElement *singleLineCommentElement;
static DuxPHPBlockCommentElement *blockCommentElement;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"'\"/#$0123456789"];
  numericCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
  nonNumericCharacterSet = [numericCharacterSet invertedSet];
  alphabeticCharacterSet = [NSCharacterSet letterCharacterSet];
  
  NSArray *keywords = [NSArray arrayWithObjects:@"class", @"extends", @"if", @"public", @"function", @"exit", nil];
  keywordsExpression = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b(%@)\\b", [keywords componentsJoinedByString:@"|"]] options:NSRegularExpressionCaseInsensitive error:NULL];
  
  singleQuoteStringElement = [DuxPHPSingleQuoteStringElement sharedInstance];
  doubleQuoteStringElement = [DuxPHPDoubleQuoteStringElement sharedInstance];
  numberElement = [DuxPHPNumberElement sharedInstance];
  variableElement = [DuxPHPVariableElement sharedInstance];
  keywordElement = [DuxPHPKeywordElement sharedInstance];
  singleLineCommentElement = [DuxPHPSingleLineCommentElement sharedInstance];
  blockCommentElement = [DuxPHPBlockCommentElement sharedInstance];
}

- (id)init
{
  return [self initWithLanguage:[DuxPHPLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  // scan up to the next character
  BOOL keepLooking = YES;
  NSUInteger searchStartLocation = startingAt;
  NSRange foundCharacterSetRange;
  unichar characterFound;
  while (keepLooking) {
    foundCharacterSetRange = [string.string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.string.length - searchStartLocation)];
    
    if (foundCharacterSetRange.location == NSNotFound)
      break;
    
    // did we find a / character? check if it's a comment or not
    characterFound = [string.string characterAtIndex:foundCharacterSetRange.location];
    if (string.string.length > (foundCharacterSetRange.location + 1) && characterFound == '/') {
      characterFound = [string.string characterAtIndex:foundCharacterSetRange.location + 1];
      if (characterFound != '/' && characterFound != '*') {
        searchStartLocation++;
        continue;
      }
    }
    
    // did we find a number? make sure it is wrapped in non-alpha characters
    else if ([numericCharacterSet characterIsMember:characterFound]) {
      BOOL prevCharIsAlphabetic;
      if (foundCharacterSetRange.location == 0) {
        prevCharIsAlphabetic = NO;
      } else {
        prevCharIsAlphabetic = [alphabeticCharacterSet characterIsMember:[string.string characterAtIndex:foundCharacterSetRange.location - 1]];
      }
      
      NSUInteger nextNonNumericCharacterLocation = [string.string rangeOfCharacterFromSet:nonNumericCharacterSet options:NSLiteralSearch range:NSMakeRange(foundCharacterSetRange.location, string.string.length - foundCharacterSetRange.location)].location;
      BOOL nextCharIsAlphabetic;
      if (nextNonNumericCharacterLocation == NSNotFound || [string.string characterAtIndex:nextNonNumericCharacterLocation] == 'x') {
        nextNonNumericCharacterLocation = string.string.length;
        nextCharIsAlphabetic = NO;
      } else {
        nextCharIsAlphabetic = [alphabeticCharacterSet characterIsMember:[string.string characterAtIndex:nextNonNumericCharacterLocation]];
      }
      
      if (prevCharIsAlphabetic || nextCharIsAlphabetic) {
        searchStartLocation = nextNonNumericCharacterLocation;
        keepLooking = YES;
        continue;
      }
    }
    
    keepLooking = NO;
  }
  
  // search for the next keyword
  NSRange foundKeywordRange = NSMakeRange(NSNotFound, 0);

  NSIndexSet *keywordIndexes = [DuxPHPLanguage keywordIndexSet];
  if (keywordIndexes) {
    NSUInteger foundKeywordMax = (foundCharacterSetRange.location == NSNotFound) ? string.string.length : foundCharacterSetRange.location;
    for (NSUInteger index = startingAt; index < foundKeywordMax; index++) {
      if ([keywordIndexes containsIndex:index]) {
        if (foundKeywordRange.location == NSNotFound) {
          foundKeywordRange.location = index;
          foundKeywordRange.length = 1;
        } else {
          foundKeywordRange.length++;
        }
      } else {
        if (foundKeywordRange.location != NSNotFound) {
          break;
        }
      }
    }
  }
  
  // scanned up to the end of the string?
  if (foundCharacterSetRange.location == NSNotFound && foundKeywordRange.location == NSNotFound)
    return string.string.length - startingAt;
  
  // did we find a keyword before a character?
  if (foundKeywordRange.location != NSNotFound) {
    if (foundCharacterSetRange.location == NSNotFound || foundKeywordRange.location < foundCharacterSetRange.location) {
      *nextElement = keywordElement;
      return foundKeywordRange.location - startingAt;
    }
  }
  
  // what character did we find?
  switch (characterFound) {
    case '\'':
      *nextElement = singleQuoteStringElement;
      return foundCharacterSetRange.location - startingAt;
    case '"':
      *nextElement = doubleQuoteStringElement;
      return foundCharacterSetRange.location - startingAt;
    case '$':
      *nextElement = variableElement;
      return foundCharacterSetRange.location - startingAt;
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
      *nextElement = numberElement;
      return foundCharacterSetRange.location - startingAt;
    case '/':
    case '#':
      *nextElement = singleLineCommentElement;
      return foundCharacterSetRange.location - startingAt;
    case '*':
      *nextElement = blockCommentElement;
      return foundCharacterSetRange.location - startingAt;
  }
  
  // should never reach this, but add this line anyway to make the compiler happy
  return string.string.length - startingAt;
}

@end
