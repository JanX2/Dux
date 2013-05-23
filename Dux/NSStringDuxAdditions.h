//
//  NSStringDuxAdditions.h
//  Dux
//
//  Created by Abhi Beckert on 2011-11-18.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Foundation/Foundation.h>
#import "DuxStringLineEnumerator.h"

enum {
  DuxNewlineUnknown = 0,
  DuxNewlineUnix = 1,
  DuxNewlineWindows = 2,
  DuxNewlineClassicMac = 4
};
typedef NSUInteger DuxNewlineOptions;

@interface NSMutableString (NSMutableStringDuxAdditions)

+ (NSMutableString *)mutableStringWithUnknownData:(NSData *)data usedEncoding:(NSStringEncoding *)enc;

@end

@interface NSString (NSStringDuxAdditions)

- (DuxStringLineEnumerator *)lineEnumeratorForLinesInRange:(NSRange)range;
- (NSRange)rangeOfLineAtOffset:(NSUInteger)location;
- (NSUInteger)beginingOfLineAtOffset:(NSUInteger)location;
- (NSUInteger)endOfLineAtOffset:(NSUInteger)location;

- (NSString *)whitespaceForLineBeginingAtLocation:(NSUInteger)lineBegining;

- (DuxNewlineOptions)newlineStyles;
- (DuxNewlineOptions)newlineStyleForFirstNewline;
+ (NSString *)stringForNewlineStyle:(DuxNewlineOptions)newlineStyle;

- (NSString *)stringByReplacingNewlinesWithNewline:(DuxNewlineOptions)newlineStyle;

- (NSUInteger)countOccurancesOfString:(NSString *)substring;

@end
