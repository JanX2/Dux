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
  NSPointerArray *lineNumbers;
  NSDictionary *textAttributes;
  DuxLanguage *language;
}

@property NSString *string;
@property (readonly) NSUInteger length;

@property DuxLanguage *language;
@property (readonly) NSDictionary *textAttributes;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

- (DuxLine *)lineAtCharacterPosition:(NSUInteger)characterPosition;

@end
