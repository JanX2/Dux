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
  
  NSMutableParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
  paragraphStyle.tabStops = @[];
  paragraphStyle.alignment = NSLeftTextAlignment;
  paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  paragraphStyle.defaultTabInterval = 14;
  paragraphStyle.headIndent = 28;
  NSFont *font = [NSFont fontWithName:@"Source Code Pro" size:13];
  if (!font)
    font = [NSFont userFixedPitchFontOfSize:13];
  textAttributes = @{NSFontAttributeName: font, NSParagraphStyleAttributeName:paragraphStyle.copy, NSForegroundColorAttributeName: (id)[[NSColor blackColor] CGColor]};
  
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
}

//- (void)setString:(NSString *)string
//{
//  contents = string.mutableCopy;
//  
//  [lines setCount:0];
//  [lines compact];
//  unsafeLinesOffset = 0;
//}

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

- (DuxLine *)lineStartingAtByteLocation:(NSUInteger)byteLocation
{
  // end of the data?
  if (byteLocation == self.length)
    return nil;
  
  // is there a newline at this byte offset? handle it specially
  if (self.length >= byteLocation + 2) {
    UInt8 possibleNewlineBytes[2];
    [self.data getBytes:&possibleNewlineBytes range:NSMakeRange(byteLocation, 2)];
    
    if (possibleNewlineBytes[0] == '\n') {
      DuxLine *line = [[DuxLine alloc] initWithString:CFAttributedStringCreate(NULL, (CFStringRef)@"", (__bridge CFDictionaryRef)(self.textAttributes)) byteRange:NSMakeRange(byteLocation, 1)];
      return line;
    } else if (possibleNewlineBytes[0] == '\r') {
      if (possibleNewlineBytes[1] == '\n') {
        DuxLine *line = [[DuxLine alloc] initWithString:CFAttributedStringCreate(NULL, (CFStringRef)@"", (__bridge CFDictionaryRef)(self.textAttributes)) byteRange:NSMakeRange(byteLocation, 2)];
        return line;
      }
      DuxLine *line = [[DuxLine alloc] initWithString:CFAttributedStringCreate(NULL, (CFStringRef)@"", (__bridge CFDictionaryRef)(self.textAttributes)) byteRange:NSMakeRange(byteLocation, 1)];
      return line;
    }
  } else if (self.length >= byteLocation + 1) {
    UInt8 possibleNewlineBytes[1];
    [self.data getBytes:&possibleNewlineBytes range:NSMakeRange(byteLocation, 1)];
    
    if (possibleNewlineBytes[0] == '\n' || possibleNewlineBytes[0] == '\r') {
      DuxLine *line = [[DuxLine alloc] initWithString:CFAttributedStringCreate(NULL, (CFStringRef)@"", (__bridge CFDictionaryRef)(self.textAttributes)) byteRange:NSMakeRange(byteLocation, 1)];
      return line;
    }
  }
  
  // fetch 1,000 bytes
  NSUInteger bytesLength = MIN(self.length - byteLocation, 1000);
  UInt8 bytes[bytesLength];
  [self.data getBytes:&bytes range:NSMakeRange(byteLocation, bytesLength)];
  
  // check if the end of the bytes is inside a utf-8 sequence
  if (bytesLength > 0) {
    UInt8 lastByte = bytes[bytesLength - 1];
    if ((lastByte & 0x80) != 0) { // is last byte a non-ASCII character?
      while (((lastByte & 0xc0) == 0x80)) { // walk backwards until we have reached the first char in the utf-8 sequence
        bytesLength--;
        lastByte = bytes[bytesLength-1];
      }
      bytesLength--; // now go back 1 more byte (to skip the first char in utf-8 sequence)
    }
  }
  
  
  
  // search for a newline
  CFIndex lineBytesLength = 0;
  CFIndex byteOffset;
  for (byteOffset = 0; byteOffset < bytesLength; byteOffset++) {
    UInt8 byte = bytes[byteOffset];
    if (byte == '\n') {
      lineBytesLength = byteOffset + 1;
      break;
    } else if (byte == '\r') {
      lineBytesLength = byteOffset + 1;
      if (lineBytesLength < bytesLength && bytes[lineBytesLength] == '\n')
        lineBytesLength++;
      break;
    }
  }
  // hit the end of the data?
  if (lineBytesLength == 0 && (byteLocation + byteOffset == self.length)) {
    lineBytesLength = bytesLength;
  }
  
  // TODO: we should decode another 1,000 bytes here and keep searching. We need to implement soft wrapping before doing this though.
  if (lineBytesLength == 0) {
    NSLog(@"Not yet implemented. Can't handle lines longer than 1,000 bytes");
    lineBytesLength = bytesLength - 1;
  }
  
  // decode the data
  CFStringRef decodedData = CFStringCreateWithBytes(NULL, bytes, lineBytesLength, kCFStringEncodingUTF8, (byteLocation == 0)); // TODO: support other encodings
  CFAttributedStringRef lineString = CFAttributedStringCreate(NULL, decodedData, (__bridge CFDictionaryRef)(self.textAttributes));
  
  // TODO: syntax highlighting might go here
  
  // create the line
  DuxLine *line = [[DuxLine alloc] initWithString:lineString byteRange:NSMakeRange(byteLocation, lineBytesLength)];
  
  return line;
}

- (DuxLine *)lineBeforeLine:(DuxLine *)line
{
  if (!line || line.range.location == 0)
    return nil;
  
  return [self lineEndingAtByteOffset:line.range.location];
}

- (DuxLine *)lineEndingAtByteOffset:(NSUInteger)lineEnd
{
  // decode 1,000 bytes before the line
  NSUInteger byteLocation = 0;
  if (lineEnd >= 1000)
    byteLocation = lineEnd - 1000;
  
  NSUInteger bytesLength = MIN(lineEnd, 1000);
  UInt8 bytes[bytesLength];
  [self.data getBytes:&bytes range:NSMakeRange(byteLocation, bytesLength)];
  
  // search for a newline
  CFIndex lineBytesLength = 0;
  CFIndex byteOffset;
  for (byteOffset = bytesLength - 1; byteOffset >= 0; byteOffset--) {
    UInt8 byte = bytes[byteOffset];
    if (byte == '\n') {
      lineBytesLength = (bytesLength - byteOffset) - 1;
      if (lineBytesLength == 0) { // this is the newline at the end of the previous line
        if (byteOffset > 1 && bytes[byteOffset - 1] == '\r') {
          byteOffset--;
        }
        
        continue;
      }
      
      break;
    } else if (byte == '\r') {
      lineBytesLength = bytesLength - byteOffset;
      if (lineBytesLength == 0) { // this is the newline at the end of the previous line
        continue;
      }
      break;
    }
  }
  // got to the beginning of our data?
  if (lineBytesLength == 0 && byteLocation == 0) {
    lineBytesLength = lineEnd;
  }
  // did we not find any newlines at all?
  if (lineBytesLength == 0) {
    NSLog(@"Not yet implemented. Can't handle lines longer than 1,000 bytes");
    lineBytesLength = bytesLength - 1;
  }
  
  // decode the data
  UInt8 lineBytes[lineBytesLength];
  memcpy(lineBytes, bytes + (bytesLength - lineBytesLength), lineBytesLength);
  CFStringRef decodedData = CFStringCreateWithBytes(NULL, lineBytes, lineBytesLength, kCFStringEncodingUTF8, (byteLocation == 0)); // TODO: support other encodings
  CFAttributedStringRef lineString = CFAttributedStringCreate(NULL, decodedData, (__bridge CFDictionaryRef)(self.textAttributes));
  
  // TODO: syntax highlighting might go here
  
  // create the line
  return [[DuxLine alloc] initWithString:lineString byteRange:NSMakeRange(lineEnd - lineBytesLength, lineBytesLength)];
}

- (DuxLine *)lineAfterLine:(DuxLine *)line
{
  if (!line || NSMaxRange(line.range) >= self.data.length)
    return nil;
  
  NSUInteger newPosition = NSMaxRange(line.range);
  if ([self positionSplitsWindowsNewline:newPosition])
    newPosition++;
  
  return [self lineStartingAtByteLocation:newPosition];
}

- (DuxLine *)lastLine
{
  if (self.length == 0)
    return nil;
  
  return [self lineEndingAtByteOffset:self.length];
}

@end
