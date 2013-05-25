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
  
  contents = [[NSData alloc] init];
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

- (NSData *)data
{
  return contents;
}

- (NSUInteger)length
{
  return contents.length;
}

- (void)setData:(NSData *)data
{
  contents = data;
  
  [lines setCount:0];
  [lines compact];
  unsafeLinesOffset = 0;
}

//- (void)setString:(NSString *)string
//{
//  contents = string.mutableCopy;
//  
//  [lines setCount:0];
//  [lines compact];
//  unsafeLinesOffset = 0;
//}

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
//  NSUInteger lineStart = unsafeLinesOffset;
//  NSUInteger lineEnd;
//  DuxLine *line;
//  if (lineStart == 0) {
//    findLinesLineCount = 0;
//    languageElementStack = @[language.baseElement].mutableCopy;
//  } else if (lineStart > contents.length) {
//    lineStart = contents.length;
//  }
//  
//  // add a couple extra characters to maxPosition, to allow a buffer for newline characters
//  maxPosition = MIN(maxPosition + 2, contents.length);
//  
//  while (true) {
//    findLinesLineCount++;
//    
//    lineEnd = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch range:NSMakeRange(lineStart, contents.length - lineStart)].location;
//    if (lineEnd == NSNotFound)
//      lineEnd = contents.length == 0 ? 0 : contents.length;
//    
//    NSRange lineRange = NSMakeRange(lineStart, lineEnd - lineStart);
//    [language prepareToParseTextStorage:self inRange:lineRange];
//    line = [[DuxLine alloc] initWithStorage:self range:lineRange lineNumber:findLinesLineCount workingElementStack:languageElementStack];
//    
//    [lines setCount:lineStart + 1];
//    [lines insertPointer:(void *)line atIndex:lineStart];
//    
//    // is it a windows newline?
//    BOOL isWindowsNewline = NO;
//    if (self.string.length >= lineEnd + 2) {
//      if ([self.string characterAtIndex:lineEnd] == '\r') {
//        if ([self.string characterAtIndex:lineEnd + 1] == '\n') {
//          isWindowsNewline = YES;
//        }
//      }
//    }
//    
//    lineStart = lineEnd + (isWindowsNewline ? 2 : 1);
//    unsafeLinesOffset = lineStart;
//    if (lineStart > maxPosition)
//      break;
//  }
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string
{
  NSLog(@"not yet implemente: %s", __PRETTY_FUNCTION__);
  
//  DuxLine *line = [self lineAtCharacterPosition:range.location];
//  
//  [contents replaceCharactersInRange:range withString:string];
//  
//  [lines setCount:range.location];
//  [lines compact];
//  unsafeLinesOffset = line.range.location;
//  findLinesLineCount = line.lineNumber - 1;
}

- (BOOL)positionSplitsWindowsNewline:(NSUInteger)byteOffset
{
  if (byteOffset == 0)
    return NO;
  
  if (byteOffset >= self.data.length)
    return NO;
  
  UInt8 bytes[2];
  [self.data getBytes:&bytes range:NSMakeRange(byteOffset -1, 2)];
  
  return (bytes[0] == '\r' && bytes[1] == '\n');
}

- (CFAttributedStringRef)substringWithByteRange:(NSRange)range
{
  UInt8 bytes[range.length];
  [self.data getBytes:&bytes range:NSMakeRange(range.location, range.length)];
  CFStringRef decodedData = CFStringCreateWithBytesNoCopy(NULL, bytes, range.length, kCFStringEncodingUTF8, (range.location == 0), NULL);
  
  CFAttributedStringRef attributedString = CFAttributedStringCreate(NULL, decodedData, (__bridge CFDictionaryRef)(self.textAttributes));
  
  return attributedString;
}

- (DuxLine *)lineAtCharacterPosition:(NSUInteger)characterPosition
{
  // TODO: search backwards ~10KB from characterPosition for a newline
  
  NSUInteger bytesLength = MIN(self.length - characterPosition, 1000);
  UInt8 bytes[bytesLength];
  [self.data getBytes:&bytes range:NSMakeRange(characterPosition, bytesLength)];
  CFStringRef decodedData = CFStringCreateWithBytes(NULL, bytes, bytesLength, kCFStringEncodingUTF8, (characterPosition == 0));
  
  CFAttributedStringRef attributedString = CFAttributedStringCreate(NULL, decodedData, (__bridge CFDictionaryRef)(self.textAttributes));
  CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attributedString);
  CFIndex lineLength = CTTypesetterSuggestLineBreak(typesetter, 0, 1000);
  
  CFAttributedStringRef lineString = CFAttributedStringCreateWithSubstring(NULL, attributedString, CFRangeMake(0, lineLength));
  
  CFIndex lineBytesLength;
  CFStringGetBytes(CFAttributedStringGetString(lineString), CFRangeMake(0, lineLength), kCFStringEncodingUTF8, 0, YES, NULL, ULONG_MAX, &lineBytesLength);
  
  DuxLine *line = [[DuxLine alloc] initWithString:lineString byteRange:NSMakeRange(characterPosition, lineBytesLength)];
  
  return line;
//  
//  
//  
//  
//  
//  if (characterPosition > self.string.length)
//    return nil;
//  
//  if (unsafeLinesOffset <= characterPosition || lines.count <= characterPosition) {
//    [self findLinesUpToPosition:characterPosition];
//  }
//  
//  if (characterPosition == 0)
//    return [lines pointerAtIndex:0];
//  
//  // are we in the middle of a windows newline?
//  if ([self positionSplitsWindowsNewline:characterPosition]) {
//    characterPosition++;
//  }
//  
//  NSUInteger lineStart;
//  NSRange lineStartRange = [self.string rangeOfCharacterFromSet:newlineCharacters options:NSLiteralSearch | NSBackwardsSearch range:NSMakeRange(0, characterPosition)];
//  if (lineStartRange.location == NSNotFound || lineStartRange.length == 0)
//    lineStart = 0;
//  else
//    lineStart = lineStartRange.location + lineStartRange.length;
//  
//  return [lines pointerAtIndex:lineStart];
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
  if (NSMaxRange(line.range) >= self.data.length)
    return nil;
  
  NSUInteger newPosition = NSMaxRange(line.range);
  if ([self positionSplitsWindowsNewline:newPosition])
    newPosition++;
  
  return [self lineAtCharacterPosition:newPosition];
}

@end
