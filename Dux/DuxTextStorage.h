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
  NSMutableString *contents;
  
  NSPointerArray *lines;
  NSUInteger unsafeLinesOffset;
  NSUInteger findLinesLineCount;
  NSMutableArray *languageElementStack;
  
  NSDictionary *textAttributes;
  DuxLanguage *language;
}

@property NSString *string;
@property (readonly) NSUInteger length;

@property DuxLanguage *language;
@property (readonly) NSDictionary *textAttributes;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

- (void)setMutableString:(NSMutableString *)string; // unlike setting the string directly, this allows you to give the text storage a mutable string that it will use internally. you must not modify this string after providing it, except via the storage

- (DuxLine *)lineAtCharacterPosition:(NSUInteger)characterPosition;
- (DuxLine *)lineBeforeLine:(DuxLine *)line;
- (DuxLine *)lineAfterLine:(DuxLine *)line;

- (BOOL)positionSplitsWindowsNewline:(NSUInteger)characterPosition; // if characterPosition is in between a \r\n pair, this returns YES. Text should never be inserted in between these two characters, but DuxTextStorage does not guard against that for you.

@end
