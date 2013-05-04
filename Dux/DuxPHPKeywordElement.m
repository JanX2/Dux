//
//  DuxPHPKeywordElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-16.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPHPKeywordElement.h"
#import "DuxPHPLanguage.h"

@implementation DuxPHPKeywordElement

static NSCharacterSet *nextElementCharacterSet;
static NSColor *color;

+ (void)initialize
{
  [super initialize];
  
  NSMutableCharacterSet *mutableCharset = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
  [mutableCharset addCharactersInString:@"_"];
  nextElementCharacterSet = [[mutableCharset copy] invertedSet];
  
  color = [NSColor colorWithCalibratedRed:0.557 green:0.031 blue:0.329 alpha:1];
}

- (id)init
{
  return [self initWithLanguage:[DuxPHPLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSString *)string startingAt:(NSUInteger)startingAt didJustPop:(BOOL)didJustPop nextElement:(DuxLanguageElement *__strong*)nextElement
{
  NSRange foundRange = [string rangeOfCharacterFromSet:nextElementCharacterSet options:NSLiteralSearch range:NSMakeRange(startingAt, string.length - startingAt)];
  
  if (foundRange.location == NSNotFound)
    return string.length - startingAt;
  
  return foundRange.location - startingAt;
}

- (NSColor *)color
{
  return color;
}

@end
