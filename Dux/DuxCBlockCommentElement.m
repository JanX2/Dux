//
//  DuxCBlockCommentElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-25.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxCBlockCommentElement.h"
#import "DuxCLanguage.h"

@implementation DuxCBlockCommentElement

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
  return [self initWithLanguage:[DuxCLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSAttributedString *)string startingAt:(NSUInteger)startingAt nextElement:(DuxLanguageElement *__strong*)nextElement
{
  NSUInteger searchStartLocation = MIN(startingAt + 2, string.length);
  NSRange foundRange = [string.string rangeOfString:nextElementSearchString options:NSLiteralSearch range:NSMakeRange(searchStartLocation, string.string.length - searchStartLocation)];
  
  if (foundRange.location == NSNotFound)
    return string.string.length - startingAt;
  
  return (foundRange.location - startingAt + 2);
}

- (NSColor *)color
{
  return color;
}

@end
