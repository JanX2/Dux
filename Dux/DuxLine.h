//
//  DuxLine.h
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class DuxTextStorage;

@interface DuxLine : CALayer

- (id)initWithStorage:(DuxTextStorage *)storage range:(NSRange)range lineNumber:(NSString *)lineNumber;

@property (readonly, weak) DuxTextStorage *storage;
@property (readonly) NSRange range;

- (CGFloat)heightWithWidth:(CGFloat)width attributes:(NSDictionary *)textAttributes;

- (CGFloat)drawInContext:(CGContextRef)context atYOffset:(CGFloat)yOffset width:(CGFloat)lineWidth attributes:(NSMutableDictionary *)attributes;

@end
