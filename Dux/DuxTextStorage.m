//
//  DuxTextStorage.m
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import "DuxTextStorage.h"
#import "DuxLine.h"
#import "DuxLanguage.h"
#import "DuxPlainTextLanguage.h"

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
  
  NSMutableParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
  paragraphStyle.tabStops = @[];
  paragraphStyle.alignment = NSLeftTextAlignment;
  paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  paragraphStyle.defaultTabInterval = 14;
  paragraphStyle.headIndent = 28;
  textAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"Source Code Pro" size:13], NSParagraphStyleAttributeName:paragraphStyle.copy, NSForegroundColorAttributeName: (id)[[NSColor blackColor] CGColor]};
  
  language = [DuxPlainTextLanguage sharedInstance];
  
  [self findLines];
  
  return self;
}

- (NSString *)string
{
  return contents;
}

- (NSUInteger)length
{
  return contents.length;
}

- (void)setString:(NSString *)string
{
  contents = string.mutableCopy;
  
  [self findLines];
}

- (DuxLanguage *)language
{
  return language;
}

- (void)setLanguage:(DuxLanguage *)newLanguage
{
  if (language == newLanguage)
    return;
  
  language = newLanguage;
}

- (NSDictionary *)textAttributes
{
  return textAttributes;
}

- (void)findLines
{
  NSUInteger index = 0;
  NSUInteger lineStart = 0;
  NSUInteger lineEnd = 0;
  DuxLine *line;
  NSMutableArray *elementStack = @[language.baseElement].mutableCopy;
  [lineNumbers setCount:0];
  [language prepareToParseTextStorage:self inRange:NSMakeRange(0, self.length)];
  while (true) {
    index++;
    
    lineEnd = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch range:NSMakeRange(lineStart, contents.length - lineStart)].location;
    if (lineEnd == NSNotFound)
      lineEnd = contents.length == 0 ? 0 : contents.length;
    
    line = [[DuxLine alloc] initWithStorage:self range:NSMakeRange(lineStart, lineEnd - lineStart) lineNumber:[NSString stringWithFormat:@"%lu", (unsigned long)index] workingElementStack:elementStack];
    
    [lineNumbers setCount:lineStart + 1];
    [lineNumbers insertPointer:(void *)line atIndex:lineStart];
    
    // is it a windows newline?
    BOOL isWindowsNewline = NO;
    if (self.string.length >= lineEnd + 2) {
      if ([self.string characterAtIndex:lineEnd] == '\r') {
        if ([self.string characterAtIndex:lineEnd + 1] == '\n') {
          isWindowsNewline = YES;
        }
      }
    }
    
    lineStart = lineEnd + (isWindowsNewline ? 2 : 1);
    if (lineStart > contents.length)
      break;
  }
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
  [contents replaceCharactersInRange:range withString:string];
  
  [self findLines];
}

- (BOOL)positionSplitsWindowsNewline:(NSUInteger)characterPosition
{
  if (characterPosition == 0)
    return NO;
  
  if (characterPosition >= self.string.length)
    return NO;
  
  if ([self.string characterAtIndex:characterPosition - 1] != '\r')
    return NO;
  
  if ([self.string characterAtIndex:characterPosition] != '\n')
    return NO;
  
  return YES;
}

- (DuxLine *)lineAtCharacterPosition:(NSUInteger)characterPosition
{
  if (characterPosition > self.string.length)
    return nil;
  
  // are we in the middle of a windows newline?
  if ([self positionSplitsWindowsNewline:characterPosition]) {
    characterPosition++;
  }
  
  NSUInteger lineStart;
  NSRange lineStartRange = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange(0, characterPosition)];
  if (lineStartRange.location == NSNotFound || lineStartRange.location == 0)
    lineStart = 0;
  else
    lineStart = lineStartRange.location + lineStartRange.length;
  
  return [lineNumbers pointerAtIndex:lineStart];
}

- (DuxLine *)lineBeforeLine:(DuxLine *)line
{
  if (line.range.location == 0)
    return nil;
  
  NSUInteger newPosition = line.range.location - 1;
  if ([self positionSplitsWindowsNewline:newPosition])
    newPosition--;
  
  return [self lineAtCharacterPosition:newPosition];
}

- (DuxLine *)lineAfterLine:(DuxLine *)line
{
  if (NSMaxRange(line.range) == (self.string.length - 1))
    return nil;
  
  NSUInteger newPosition = NSMaxRange(line.range) + 1;
  if ([self positionSplitsWindowsNewline:newPosition])
    newPosition++;
  
  return [self lineAtCharacterPosition:newPosition];
}

@end
