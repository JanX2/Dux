//
//  DuxTextStorage.m
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import "DuxTextStorage.h"
#import "DuxLine.h"

@implementation DuxTextStorage

- (id)init
{
  if (!(self = [super init]))
    return nil;
  
  contents = [[NSMutableString alloc] init];
  
  return self;
}

- (NSString *)string
{
  return contents;
}

- (void)setString:(NSString *)string
{
  contents = string.mutableCopy;
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
  [contents replaceCharactersInRange:range withString:string];
}

- (DuxLine *)lineAtCharacterPosition:(NSUInteger)characterPosition
{
  if (characterPosition >= self.string.length)
    return nil;
  
  NSCharacterSet *newlineCharacters = [NSCharacterSet newlineCharacterSet];
  
  NSUInteger lineStart, lineEnd;
  
  NSRange lineStartRange = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange(0, characterPosition)];
  if (lineStartRange.location == NSNotFound || lineStartRange.location == 0)
    lineStart = 0;
  else
    lineStart = lineStartRange.location + lineStartRange.length;
  
  if (lineStart == (self.string.length - 1)) {
    lineEnd = NSNotFound;
  } else {
    lineEnd = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch range:NSMakeRange(lineStart, self.string.length - lineStart)].location;
  }
  if (lineEnd == NSNotFound)
    lineEnd = self.string.length;
  
  return [[DuxLine alloc] initWithStorage:self range:NSMakeRange(lineStart, lineEnd - lineStart)];
}

@end
