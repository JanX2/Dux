//
//  DuxPHPBlockCommentElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-16.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPHPBlockCommentElement.h"
#import "DuxPHPLanguage.h"

@implementation DuxPHPBlockCommentElement

static NSString *nextElementSearchString;
static NSColor *color;

+ (void)initialize
{
  [super initialize];
  
  nextElementSearchString = @"*/";
  
  color = [NSColor colorWithCalibratedRed:0.075 green:0.529 blue:0.000 alpha:1];
}

- (id)init
{
  return [self initWithLanguage:[DuxPHPLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSString *)string startingAt:(NSUInteger)startingAt didJustPop:(BOOL)didJustPop nextElement:(DuxLanguageElement *__strong*)nextElement
{
  NSUInteger searchStartLocation = startingAt + 2;
  NSRange foundRange = [string rangeOfString:nextElementSearchString options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.length - searchStartLocation)];
  
  if (foundRange.location == NSNotFound)
    return string.length - startingAt;
  
  return (foundRange.location - startingAt + 2);
}

- (NSColor *)color
{
  return color;
}

@end
