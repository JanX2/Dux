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
  while (index <= 99999) {
    index++;
    
    [lineNumbers setCount:lineStart + 1];
    
    [lineNumbers insertPointer:(void *)[NSString stringWithFormat:@"%lu", (unsigned long)index] atIndex:lineStart];
    
    lineStart = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch range:NSMakeRange(lineStart, contents.length - lineStart)].location;
    if (lineStart == NSNotFound)
      break;
    
    lineStart++;
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
  
  return [[DuxLine alloc] initWithStorage:self range:NSMakeRange(lineStart, lineEnd - lineStart) lineNumber:[lineNumbers pointerAtIndex:lineStart]];
}

@end
