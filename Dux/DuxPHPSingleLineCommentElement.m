//
//  DuxPHPSingleLineCommentElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-16.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPHPSingleLineCommentElement.h"
#import "DuxPHPLanguage.h"

@implementation DuxPHPSingleLineCommentElement

static NSCharacterSet *nextElementCharacterSet;
static NSColor *color;

+ (void)initialize
{
  [super initialize];
  
  nextElementCharacterSet = [NSCharacterSet newlineCharacterSet];
  
  color = [NSColor colorWithCalibratedRed:0.075 green:0.529 blue:0.000 alpha:1];
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

- (BOOL)isComment
{
  return YES;
}

@end
