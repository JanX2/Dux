//
//  DuxLine.m
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import "DuxLine.h"
#import "DuxTextStorage.h"

@interface DuxLine ()

@property (weak) DuxTextStorage *storage;
@property NSRange range;

@end

@implementation DuxLine

static NSCharacterSet *nonWhitespaceCharacterSet;

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nonWhitespaceCharacterSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
  });
}

- (id)initWithStorage:(DuxTextStorage *)storage range:(NSRange)range
{
  if (!(self = [super init]))
    return nil;
  
  self.storage = storage;
  self.range = range;
  
  return self;
}

- (CGFloat)heightWithWidth:(CGFloat)width attributes:(NSDictionary *)textAttributes
{
  NSAttributedString *stringToDraw = [[NSAttributedString alloc] initWithString:[self.storage.string substringWithRange:self.range] attributes:textAttributes];
  
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)stringToDraw);
  CGSize lineSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.range.length), nil, CGSizeMake(width, CGFLOAT_MAX), NULL);
  
  return lineSize.height;
}

- (void)drawInContext:(CGContextRef)context
{
  NSMutableParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
  paragraphStyle.tabStops = @[];
  paragraphStyle.alignment = NSLeftTextAlignment;
  paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  paragraphStyle.defaultTabInterval = 14;
  paragraphStyle.headIndent = 28;
  NSDictionary *textAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"Source Code Pro" size:12], NSParagraphStyleAttributeName:paragraphStyle.copy};
  
  [self drawInContext:context atYOffset:0 width:self.frame.size.width attributes:textAttributes.mutableCopy];
}

- (CGFloat)drawInContext:(CGContextRef)context atYOffset:(CGFloat)yOffset width:(CGFloat)lineWidth attributes:(NSMutableDictionary *)attributes
{
  CGColorRef bgColor = [NSColor whiteColor].CGColor;
  CGContextSetFillColorWithColor(context, bgColor);
  CGContextFillRect(context, self.bounds);
  
  // calculate head indent
  NSUInteger whitespaceEnd = [self.storage.string rangeOfCharacterFromSet:nonWhitespaceCharacterSet options:NSLiteralSearch range:self.range].location;
  CGFloat headIndent = 28; // default
  NSParagraphStyle *paragraphStyle = [attributes objectForKey:NSParagraphStyleAttributeName];
  if (whitespaceEnd != NSNotFound && whitespaceEnd != self.range.location) {
    headIndent += [[self.storage.string substringWithRange:NSMakeRange(self.range.location, whitespaceEnd - self.range.location)] sizeWithAttributes:attributes].width;
  }
  
  // if headIndent is different to attributes, update them
  if (fabs(paragraphStyle.headIndent - headIndent) > 0.1) {
    NSMutableParagraphStyle *mutableParagraphStyle = paragraphStyle.mutableCopy;
    mutableParagraphStyle.headIndent = headIndent;
    paragraphStyle = mutableParagraphStyle.copy;
    
    [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
  }
  
  // load attributed string
  NSAttributedString *stringToDraw;
  if (self.range.length > 0) {
    stringToDraw = [[NSAttributedString alloc] initWithString:[self.storage.string substringWithRange:self.range] attributes:attributes];
  } else {
    stringToDraw = [[NSAttributedString alloc] initWithString:@" " attributes:attributes]; // empty line has zero height, so we force a space
  }
  
  //Create Frame
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)stringToDraw);
  CGFloat lineHeight = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.range.length), nil, CGSizeMake(lineWidth, CGFLOAT_MAX), NULL).height;
  CGRect lineRect = (CGRect){{0, 0}, {lineWidth, lineHeight}};
  lineRect.origin.y = self.frame.size.height - lineRect.size.height;
  
  //Draw Frame
  CGPathRef path = CGPathCreateWithRect(lineRect, NULL);
  CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
  CTFrameDraw(frame, context);
  CFRelease(path);
  
  // move to next line
  return yOffset - lineHeight;
}

@end
