//
//  DuxLine.m
//  DuxTextView
//
//  Created by Abhi Beckert on 2013-4-23.
//  Copyright (c) 2013 Abhi Beckert. All rights reserved.
//

#import "DuxLine.h"
#import "DuxTextStorage.h"
#import "DuxPreferences.h"
#import "DuxLanguageElement.h"

#define DUX_LINE_NUMBER_WIDTH 40
static NSDictionary *lineNumberAttributes;

@interface DuxLine ()

@property (weak) DuxTextStorage *storage;
@property NSRange range;
@property NSUInteger lineNumber;

@property NSArray *elements;

@end

@implementation DuxLine

static NSCharacterSet *nonWhitespaceCharacterSet;

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nonWhitespaceCharacterSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
    
    NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle alloc] init] mutableCopy];
    [paragraphStyle setAlignment:NSRightTextAlignment];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
    if ([DuxPreferences editorDarkMode]) {
      lineNumberAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:@"Source Code Pro ExtraLight" size:10], NSFontAttributeName,
                              [NSColor colorWithCalibratedWhite:1 alpha:0.8].CGColor, NSForegroundColorAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName,
                              nil];
    } else {
      lineNumberAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:@"Source Code Pro Light" size:10], NSFontAttributeName,
                              [NSColor colorWithCalibratedWhite:0 alpha:1].CGColor, NSForegroundColorAttributeName,
                              paragraphStyle, NSParagraphStyleAttributeName,
                              nil];
    }
    
  });
}

- (id)initWithStorage:(DuxTextStorage *)storage range:(NSRange)range lineNumber:(NSUInteger)lineNumber workingElementStack:(NSMutableArray *)elementStack
{
  if (!(self = [super init]))
    return nil;
  
  self.storage = storage;
  self.range = range;
  self.lineNumber = lineNumber;
  self.drawsAsynchronously = NO;
  self.contentsScale = [NSScreen mainScreen].backingScaleFactor;
  
  self.contentsGravity = kCAGravityTopLeft;
  self.autoresizingMask = kCALayerMinYMargin | kCALayerMaxXMargin;
  
  
  NSUInteger elementStart = range.location;
  DuxLanguageElement *element = elementStack.lastObject;
  DuxLanguageElement *nextElement = nil;
  BOOL didJustPop = NO;
  NSUInteger maxRange = NSMaxRange(range);
  
  NSMutableArray *mutableElements = [[NSMutableArray alloc] init];
  while (elementStart < maxRange) {
    nextElement = nil;
    NSUInteger elementLength = [element lengthInString:storage.string startingAt:elementStart didJustPop:didJustPop nextElement:&nextElement];
    
    BOOL isLongerThanLine = ((elementStart + elementLength) > maxRange);
    if (isLongerThanLine)
      elementLength = maxRange - elementStart;
    
    if (elementLength == 0 && nextElement == element) {
      // endless loop?
      break;
    }
    
    if (element && elementLength > 0) {
      [mutableElements addObject:@{@"element": element, @"start": [NSNumber numberWithUnsignedInteger:elementStart - range.location], @"length": [NSNumber numberWithUnsignedInteger:elementLength]}];
    }
    
    if (isLongerThanLine)
      break;
    
    if (nextElement) {
      [elementStack addObject:nextElement];
      
      element = nextElement;
      didJustPop = NO;
    } else {
      [elementStack removeLastObject];
      
      element = elementStack.lastObject;
      didJustPop = YES;
    }
    
    elementStart = elementStart + elementLength;
  }
  self.elements = mutableElements.copy;
  
  return self;
}

- (NSAttributedString *)stringToDrawWithSyntaxAttributes:(BOOL)withSyntax
{
  NSUInteger whitespaceEnd = [self.storage.string rangeOfCharacterFromSet:nonWhitespaceCharacterSet options:NSLiteralSearch range:self.range].location;
  CGFloat headIndent = 28; // default
  NSMutableDictionary *attributes = self.storage.textAttributes.mutableCopy;
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
  
  NSMutableAttributedString *stringToDraw;
  if (self.range.length > 0) {
    stringToDraw = [[NSMutableAttributedString alloc] initWithString:[self.storage.string substringWithRange:self.range] attributes:attributes];
  } else {
    stringToDraw = [[NSMutableAttributedString alloc] initWithString:@" " attributes:attributes]; // empty line has zero height, so we force a space
  }
  
  // apply syntax colors
  
  //  [stringToDraw addAttribute:NSBackgroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(0, stringToDraw.length)];
  for (NSDictionary *elementRecord in self.elements) {
    //    NSLog(@"%@ %@ %@", [[elementRecord valueForKey:@"element"] color], [elementRecord valueForKey:@"start"], [elementRecord valueForKey:@"length"]);
    [stringToDraw addAttribute:NSForegroundColorAttributeName value:(id)[[elementRecord valueForKey:@"element"] color].CGColor range:NSMakeRange([[elementRecord valueForKey:@"start"] unsignedIntegerValue], [[elementRecord valueForKey:@"length"] unsignedIntegerValue])];
  }
  
  return stringToDraw;
}

- (CGFloat)heightWithWidth:(CGFloat)width
{
  NSAttributedString *stringToDraw = [self stringToDrawWithSyntaxAttributes:NO];
  
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)stringToDraw);
  CGSize lineSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.range.length), nil, CGSizeMake(width - DUX_LINE_NUMBER_WIDTH, CGFLOAT_MAX), NULL);
  
  return lineSize.height;
}

- (CGPoint)pointForCharacterOffset:(NSUInteger)characterOffset
{
  if (characterOffset == self.range.location)
    return CGPointMake(DUX_LINE_NUMBER_WIDTH, 0);
  
  NSUInteger adjustedOffset = characterOffset - self.range.location;
  
  NSAttributedString *stringToDraw = [self stringToDrawWithSyntaxAttributes:NO];
  
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)stringToDraw);
  
  CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, CGRectMake(self.bounds.origin.x + DUX_LINE_NUMBER_WIDTH, 0, self.bounds.size.width - DUX_LINE_NUMBER_WIDTH, self.bounds.size.height));
  CTFrameRef ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
  
  CFArrayRef lines = CTFrameGetLines(ctframe);
  CFIndex lineIndex, lineCount = CFArrayGetCount(lines);
  for (lineIndex = 0; lineIndex < lineCount; lineIndex++) {
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    CFRange lineRange = CTLineGetStringRange(line);
    if (adjustedOffset >= lineRange.location && adjustedOffset <= (lineRange.location + lineRange.length)) {
      return CGPointMake(CTLineGetOffsetForStringIndex(line, adjustedOffset - lineRange.location, NULL) + DUX_LINE_NUMBER_WIDTH, 0);
    }
  }
  
  return CGPointMake(FLT_MAX, 0);
}

- (void)drawInContext:(CGContextRef)context
{
  [self drawInContext:context atYOffset:0 width:self.frame.size.width];
}

- (CGFloat)drawInContext:(CGContextRef)context atYOffset:(CGFloat)yOffset width:(CGFloat)lineWidth
{
  CGColorRef bgColor = [NSColor whiteColor].CGColor;
  CGContextSetFillColorWithColor(context, bgColor);
  CGContextFillRect(context, self.bounds);
  
  // calculate head indent
  
  
  // load attributed string
  NSAttributedString *stringToDraw = [self stringToDrawWithSyntaxAttributes:YES];
  
  //Create Frame
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)stringToDraw);
  CGFloat lineHeight = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.range.length), nil, CGSizeMake(lineWidth - DUX_LINE_NUMBER_WIDTH, CGFLOAT_MAX), NULL).height;
  CGRect lineRect = (CGRect){{DUX_LINE_NUMBER_WIDTH, 0}, {lineWidth - DUX_LINE_NUMBER_WIDTH, lineHeight}};
  lineRect.origin.y = self.frame.size.height - lineRect.size.height;
  
  //Draw Frame
  CGPathRef path = CGPathCreateWithRect(lineRect, NULL);
  CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
  CTFrameDraw(frame, context);
  CFRelease(path);
  
  // draw line number
  if (self.lineNumber != NSUIntegerMax) {
    NSAttributedString *lineNumberString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu", self.lineNumber] attributes:lineNumberAttributes]; // empty line has zero height, so we force a space
    framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)lineNumberString);
    
    lineRect.origin.x = 0;
    lineRect.origin.y -= 2;
    lineRect.size.width = DUX_LINE_NUMBER_WIDTH - 10;
    path = CGPathCreateWithRect(lineRect, NULL);
    frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);
    CFRelease(path);
  }
  
  // move to next line
  return yOffset - lineHeight;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<DuxLine %lu,%lu>: \"%@\"", (unsigned long)self.range.location, (unsigned long)self.range.length, [self.storage.string substringWithRange:self.range]];
}

@end
