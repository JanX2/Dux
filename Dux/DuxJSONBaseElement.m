//  DuxJavaScriptLanguage.h
//  Dux
//
//  Created by Chen Hongzhi on 6/21/12.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxJSONBaseElement.h"
#import "DuxJSONLanguage.h"
#import "DuxJSONKeyElement.h"
#import "DuxJSONStringElement.h"
#import "DuxJSONNumberElement.h"
#import "DuxJSONKeywordElement.h"

static NSCharacterSet *nextElementCharacterSet;
static NSCharacterSet *keyElementCharacterSet;
static DuxJSONKeyElement *keyElement;
static DuxJSONStringElement *stringElement;
static DuxJSONNumberElement *numberElement;
static DuxJSONKeywordElement *keywordElement;

@implementation DuxJSONBaseElement

+ (void)initialize
{
  if (self == [DuxJSONBaseElement class]) {
    nextElementCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"0123456789"];
    keyElementCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\\"];
    
    keyElement = [DuxJSONKeyElement sharedInstance];
    stringElement = [DuxJSONStringElement sharedInstance];
    numberElement = [DuxJSONNumberElement sharedInstance];
    keywordElement = [DuxJSONKeywordElement sharedInstance];
  }
}

- (id)init
{
  return [self initWithLanguage:[DuxJSONLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  NSRange foundCharacterSetRange = [string.string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(startingAt, string.length - startingAt)];
  
  NSRange foundKeywordRange = NSMakeRange(NSNotFound, 0);
  NSIndexSet *keywordIndexes = [DuxJSONLanguage keywordIndexSet];
  
  if (keywordIndexes) {
    NSUInteger foundKeywordMax = (foundCharacterSetRange.location == NSNotFound) ? string.length : foundCharacterSetRange.location;
    for (NSUInteger idx = startingAt; idx < foundKeywordMax; idx++) {
      if ([keywordIndexes containsIndex:idx]) {
        if (foundKeywordRange.location == NSNotFound) {
          foundKeywordRange.location = idx;
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
  
  if (foundCharacterSetRange.location == NSNotFound && foundKeywordRange.location == NSNotFound)
    return string.length - startingAt;
  
  if (foundKeywordRange.location != NSNotFound) {
    if (foundCharacterSetRange.location == NSNotFound || foundKeywordRange.location < foundCharacterSetRange.location) {
      *nextElement = keywordElement;
      return foundKeywordRange.location - startingAt;
    }
  }
  
  unichar characterFound = [string.string characterAtIndex:foundCharacterSetRange.location];
  
  BOOL isKeyStart = NO;
  if (characterFound == '"') {
    NSRange foundQuoteRange;
    NSUInteger searchStartLocation = foundCharacterSetRange.location + 1;
    BOOL keepLooking = YES;
    
    while (keepLooking) {
      foundQuoteRange = [string.string rangeOfCharacterFromSet:keyElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.length - searchStartLocation)];
      
      if (foundQuoteRange.location == NSNotFound || foundQuoteRange.location == (string.length - 1))
        return string.length - startingAt;
      
      characterFound = [string.string characterAtIndex:foundQuoteRange.location];
      if (characterFound == '\\') {
        searchStartLocation = foundQuoteRange.location + 2;
        continue;
      }
      
      NSUInteger location = foundQuoteRange.location + 1;
      unichar character;
      while (location < string.length) {
        character = [string.string characterAtIndex:location];
        location++;
        
        if (isspace(character))
          continue;
        
        if (character == ':')
          isKeyStart = YES;
        
        break;
      }
      
      keepLooking = NO;
    }
  }
  
  switch (characterFound) {
    case '"':
      *nextElement = isKeyStart ? keyElement : stringElement;
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
  }
  
  return string.length - startingAt;
}


@end
