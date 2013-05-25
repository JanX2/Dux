//
//  DuxTextStorage.h
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DuxLine, DuxLanguage;

@interface DuxTextStorage : NSObject
{
  NSData *contents;
  
  NSPointerArray *lines;
  NSUInteger unsafeLinesOffset;
  NSUInteger findLinesLineCount;
  NSMutableArray *languageElementStack;
  
  NSDictionary *textAttributes;
  DuxLanguage *language;
}

@property NSData *data;
@property (readonly) NSUInteger length;

@property DuxLanguage *language;
@property (readonly) NSDictionary *textAttributes;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

- (CFAttributedStringRef)substringWithByteRange:(NSRange)range;

- (DuxLine *)lineStartingAtByteLocation:(NSUInteger)byteLocation;
- (DuxLine *)lineBeforeLine:(DuxLine *)line;
- (DuxLine *)lineAfterLine:(DuxLine *)line;

- (BOOL)positionSplitsWindowsNewline:(NSUInteger)byteOffset; // check if the byte before this offset is \r and the byte after is \n

@end
