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
  lines = [NSPointerArray strongObjectsPointerArray];
  unsafeLinesOffset = 0;
  
  NSMutableParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
  paragraphStyle.tabStops = @[];
  paragraphStyle.alignment = NSLeftTextAlignment;
  paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  paragraphStyle.defaultTabInterval = 14;
  paragraphStyle.headIndent = 28;
  textAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"Source Code Pro" size:13], NSParagraphStyleAttributeName:paragraphStyle.copy, NSForegroundColorAttributeName: (id)[[NSColor blackColor] CGColor]};
  
  language = [DuxPlainTextLanguage sharedInstance];
  
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

- (void)setMutableString:(NSMutableString *)string
{
  contents = string;
  
  [lines setCount:0];
  [lines compact];
  unsafeLinesOffset = 0;
}

- (void)setString:(NSString *)string
{
  contents = string.mutableCopy;
  
  [lines setCount:0];
  [lines compact];
  unsafeLinesOffset = 0;
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

- (void)findLinesUpToPosition:(NSUInteger)maxPosition
{
  NSUInteger lineStart = unsafeLinesOffset;
  NSUInteger lineEnd;
  DuxLine *line;
  if (lineStart == 0) {
    findLinesLineCount = 0;
    languageElementStack = @[language.baseElement].mutableCopy;
  } else if (lineStart > contents.length) {
    lineStart = contents.length;
  }
  
  // add a couple extra characters to maxPosition, to allow a buffer for newline characters
  maxPosition = MIN(maxPosition + 2, contents.length);
  
  while (true) {
    findLinesLineCount++;
    
    lineEnd = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch range:NSMakeRange(lineStart, contents.length - lineStart)].location;
    if (lineEnd == NSNotFound)
      lineEnd = contents.length == 0 ? 0 : contents.length;
    
    NSRange lineRange = NSMakeRange(lineStart, lineEnd - lineStart);
    [language prepareToParseTextStorage:self inRange:lineRange];
    line = [[DuxLine alloc] initWithStorage:self range:lineRange lineNumber:findLinesLineCount workingElementStack:languageElementStack];
    
    [lines setCount:lineStart + 1];
    [lines insertPointer:(void *)line atIndex:lineStart];
    
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
    unsafeLinesOffset = lineStart;
    if (lineStart > maxPosition)
      break;
  }
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
  DuxLine *line = [self lineAtCharacterPosition:range.location];
  
  [contents replaceCharactersInRange:range withString:string];
  
  [lines setCount:range.location];
  [lines compact];
  unsafeLinesOffset = line.range.location;
  findLinesLineCount = line.lineNumber - 1;
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
  
  if (unsafeLinesOffset <= characterPosition || lines.count <= characterPosition) {
    [self findLinesUpToPosition:characterPosition];
  }
  
  if (characterPosition == 0)
    return [lines pointerAtIndex:0];
  
  // are we in the middle of a windows newline?
  if ([self positionSplitsWindowsNewline:characterPosition]) {
    characterPosition++;
  }
  
  NSUInteger lineStart;
  NSRange lineStartRange = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange(0, characterPosition)];
  if (lineStartRange.location == NSNotFound || lineStartRange.length == 0)
    lineStart = 0;
  else
    lineStart = lineStartRange.location + lineStartRange.length;
  
  return [lines pointerAtIndex:lineStart];
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
  if (NSMaxRange(line.range) >= self.string.length
      )
    return nil;
  
  NSUInteger newPosition = NSMaxRange(line.range) + 1;
  if ([self positionSplitsWindowsNewline:newPosition])
    newPosition++;
  
  return [self lineAtCharacterPosition:newPosition];
}

@end
