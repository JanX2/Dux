//
//  DuxJavaScriptBaseElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-25.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxJavaScriptBaseElement.h"
#import "DuxJavaScriptLanguage.h"
#import "DuxJavaScriptSingleQuotedStringElement.h"
#import "DuxJavaScriptDoubleQuotedStringElement.h"
#import "DuxJavaScriptNumberElement.h"
#import "DuxJavaScriptKeywordElement.h"
#import "DuxJavaScriptSingleLineCommentElement.h"
#import "DuxJavaScriptBlockCommentElement.h"
#import "DuxJavaScriptRegexElement.h"

@implementation DuxJavaScriptBaseElement

static NSCharacterSet *nextElementCharacterSet;

static DuxJavaScriptSingleQuotedStringElement *singleQuotedStringElement;
static DuxJavaScriptDoubleQuotedStringElement *doubleQuotedStringElement;
static DuxJavaScriptNumberElement *numberElement;
static DuxJavaScriptKeywordElement *keywordElement;
static DuxJavaScriptSingleLineCommentElement *singleLineCommentElement;
static DuxJavaScriptBlockCommentElement *blockCommentElement;
static DuxJavaScriptRegexElement *regexElement;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"'\"/0123456789"];
  
  singleQuotedStringElement = [DuxJavaScriptSingleQuotedStringElement sharedInstance];
  doubleQuotedStringElement = [DuxJavaScriptDoubleQuotedStringElement sharedInstance];
  numberElement = [DuxJavaScriptNumberElement sharedInstance];
  keywordElement = [DuxJavaScriptKeywordElement sharedInstance];
  singleLineCommentElement = [DuxJavaScriptSingleLineCommentElement sharedInstance];
  blockCommentElement = [DuxJavaScriptBlockCommentElement sharedInstance];
  regexElement = [DuxJavaScriptRegexElement sharedInstance];
}

- (id)init
{
  return [self initWithLanguage:[DuxJavaScriptLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  // scan up to the next character
  BOOL keepLooking = YES;
  NSUInteger searchStartLocation = startingAt;
  NSRange foundCharacterSetRange;
  unichar characterFound;
  BOOL foundSingleLineComment = NO;
  BOOL foundRegexPattern = NO;
  while (keepLooking) {
    foundCharacterSetRange = [string.string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.string.length - searchStartLocation)];
    
    if (foundCharacterSetRange.location == NSNotFound)
      break;
    
    // did we find a / character? check if it's a comment or a regex pattern
    characterFound = [string.string characterAtIndex:foundCharacterSetRange.location];
    if (characterFound == '/') {
      if (string.string.length > (foundCharacterSetRange.location + 1)) {
        characterFound = [string.string characterAtIndex:foundCharacterSetRange.location + 1];
        if (characterFound == '/') {
          foundSingleLineComment = YES;
          foundRegexPattern = NO;
        } else if (characterFound == '*') {
          foundSingleLineComment = NO;
          foundRegexPattern = NO;
        } else if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:characterFound]) { // whitespace, not a regex pattern
          foundSingleLineComment = NO;
          foundRegexPattern = NO;
          keepLooking = YES;
          searchStartLocation += 1;
          continue;
        } else { // regex pattern
          foundSingleLineComment = NO;
          foundRegexPattern = YES;
          characterFound = '/';
        }
      } else { // regex pattern
        foundSingleLineComment = NO;
        foundRegexPattern = YES;
        characterFound = '/';
      }
    }
    
    keepLooking = NO;
  }
  
  // search for the next keyword
  NSRange foundKeywordRange = NSMakeRange(NSNotFound, 0);

  NSIndexSet *keywordIndexes = [DuxJavaScriptLanguage keywordIndexSet];
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
      *nextElement = singleQuotedStringElement;
      return foundCharacterSetRange.location - startingAt;
    case '"':
      *nextElement = doubleQuotedStringElement;
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
      if (foundSingleLineComment) {
        *nextElement = singleLineCommentElement;
        return foundCharacterSetRange.location - startingAt;
      } else if (foundRegexPattern) {
        *nextElement = regexElement;
        return foundCharacterSetRange.location - startingAt;
      }
    case '*':
      *nextElement = blockCommentElement;
      return foundCharacterSetRange.location - startingAt;
  }
  
  // should never reach this, but add this line anyway to make the compiler happy
  return string.string.length - startingAt;
}

@end
