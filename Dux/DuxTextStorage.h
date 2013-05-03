//
//  DuxTextStorage.h
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DuxLine;

@interface DuxTextStorage : NSObject
{
  NSMutableString *contents;
  NSPointerArray *lineNumbers;
}

@property NSString *string;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string;

- (DuxLine *)lineAtCharacterPosition:(NSUInteger)characterPosition;

@end
