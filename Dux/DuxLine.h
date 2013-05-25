//
//  DuxLine.h
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#define DUX_LINE_NUMBER_WIDTH 80
#define DUX_LINE_HEIGHT 17
#define DUX_LINE_MAX_WRAPPED_LINES 10
#define DUX_LINE_MAX_STRING_TO_DRAW_LENGTH 10000

@class DuxTextStorage;

@interface DuxLine : CALayer
{
  CFAttributedStringRef stringToDraw;
  CTTypesetterRef typesetter;
}

- (id)initWithString:(CFAttributedStringRef)string byteRange:(NSRange)range;

@property (readonly, weak) DuxTextStorage *storage;
@property (readonly) NSRange range;
@property (readonly) NSUInteger lineNumber;

- (CGPoint)pointForCharacterOffset:(NSUInteger)characterOffset; // char offset relative to entire storage. point relative to this line's frame
- (NSUInteger)characterOffsetForPoint:(CGPoint)point; // char offset relative to entire storage. point relative to this line's frame

- (void)setFrameWithTopLeftOrigin:(NSPoint)point width:(CGFloat)width; // height is set automatically

@end
