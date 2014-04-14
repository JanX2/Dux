//
//  NSTextStorageDuxAdditions.h
//  Dux
//
//  Created by Chen Hongzhi on 2/25/14.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Cocoa/Cocoa.h>

@interface NSTextStorage (NSTextStorageDuxAdditions)

@property (nonatomic) BOOL usedForDuxTextView;

- (NSUInteger)dux_nextWordFromIndex:(NSUInteger)index forward:(BOOL)flag;
- (NSRange)dux_doubleClickAtIndex:(NSUInteger)location;

@end
