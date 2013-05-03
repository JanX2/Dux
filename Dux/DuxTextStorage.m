//
//  DuxTextStorage.m
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import "DuxTextStorage.h"
#import "DuxLine.h"

static NSCharacterSet *newlineCharacters;

@implementation DuxTextStorage

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    newlineCharacters = [NSCharacterSet newlineCharacterSet];
  });
}

- (id)init
{
  if (!(self = [super init]))
    return nil;
  
  contents = [[NSMutableString alloc] init];
  lineNumbers = [NSPointerArray strongObjectsPointerArray];
  
  [self findLineNumbers];
  
  return self;
}

- (NSString *)string
{
  return contents;
}

- (void)setString:(NSString *)string
{
  contents = string.mutableCopy;
  [self findLineNumbers];
}

- (void)findLineNumbers
{
  // find line numbers
  NSUInteger index = 0;
  NSUInteger lineStart = 0;
  NSUInteger lineEnd = 0;
  DuxLine *line;
  while (index <= 99999) {
    index++;
    
    lineEnd = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch range:NSMakeRange(lineStart, contents.length - lineStart)].location;
    if (lineEnd == NSNotFound)
      lineEnd = contents.length - 1;
    
    line = [[DuxLine alloc] initWithStorage:self range:NSMakeRange(lineStart, lineEnd - lineStart) lineNumber:[NSString stringWithFormat:@"%lu", (unsigned long)index]];
    
    [lineNumbers setCount:lineStart + 1];
    [lineNumbers insertPointer:(void *)line atIndex:lineStart];
    
    lineStart = lineEnd + 1;
    if (lineStart >= contents.length)
      break;
  }
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
  [contents replaceCharactersInRange:range withString:string];
}

- (DuxLine *)lineAtCharacterPosition:(NSUInteger)characterPosition
{
  if (characterPosition >= self.string.length)
    return nil;
  
  NSUInteger lineStart;
  NSRange lineStartRange = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange(0, characterPosition)];
  if (lineStartRange.location == NSNotFound || lineStartRange.location == 0)
    lineStart = 0;
  else
    lineStart = lineStartRange.location + lineStartRange.length;
  
  return [lineNumbers pointerAtIndex:lineStart];
}

@end
