//
//  DuxCSSNumberValueElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-20.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxCSSNumberValueElement.h"
#import "DuxCSSLanguage.h"

@implementation DuxCSSNumberValueElement

static NSCharacterSet *nextElementCharacterSet;
static NSColor *color;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@".0123456789"] invertedSet];
  
  color = [NSColor colorWithCalibratedRed:0.255 green:0.008 blue:0.847 alpha:1.000];
}

- (id)init
{
  return [self initWithLanguage:[DuxCSSLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  // find next character
  NSUInteger searchStart = startingAt + 1;
  NSUInteger stringLength = string.length;
  NSRange foundRange = [string.string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(searchStart, stringLength - searchStart)];
  
  // not found, or the last character in the string?
  if (foundRange.location == NSNotFound || foundRange.location == (stringLength - 1))
    return stringLength - startingAt;
  
  // did we just find a known measurment unit (px, pt, %, etc)
  if (stringLength > foundRange.location + 1 && [[string.string substringWithRange:NSMakeRange(foundRange.location, 1)] isEqualToString:@"%"]) {
    foundRange.location += 1;
  } else if (stringLength > foundRange.location + 2) {
    NSString *unit = [string.string substringWithRange:NSMakeRange(foundRange.location, 2)];
    
    if ([unit isEqualToString:@"px"]) {
      foundRange.location += 2;
    }
    else if ([unit isEqualToString:@"pt"]) {
      foundRange.location += 2;
    }
    else if ([unit isEqualToString:@"in"]) {
      foundRange.location += 2;
    }
    else if ([unit isEqualToString:@"cm"]) {
      foundRange.location += 2;
    }
    else if ([unit isEqualToString:@"mm"]) {
      foundRange.location += 2;
    }
    else if ([unit isEqualToString:@"em"]) {
      foundRange.location += 2;
    }
    else if ([unit isEqualToString:@"ex"]) {
      foundRange.location += 2;
    }
    else if ([unit isEqualToString:@"pc"]) {
      foundRange.location += 2;
    }
  }
  
  return foundRange.location - startingAt;
}

- (NSColor *)color
{
  return color;
}

@end
