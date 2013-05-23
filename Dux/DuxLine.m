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
  
  [self createStringToDraw];
  typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(stringToDraw));
  
  return self;
}

- (void)setFrameWithTopLeftOrigin:(NSPoint)point width:(CGFloat)width
{
  CGFloat height;
  if (fabs(self.frame.size.width) < 0.1 || fabs(width - self.frame.size.width) > 0.1) {
    // Find a break for line from the beginning of the string to the given width.
    CFIndex start = 0;
    height = 0;
    CGFloat maxHeight = (DUX_LINE_HEIGHT * (DUX_LINE_MAX_WRAPPED_LINES + 1)) - 1; // -1px incase of floating point error
    CGFloat lineWidth = width - DUX_LINE_NUMBER_WIDTH;
    lineCount = 0;
    CFMutableArrayRef mutableLines = CFArrayCreateMutable(NULL, DUX_LINE_MAX_WRAPPED_LINES, NULL);
    while (start < stringToDraw.length && height < maxHeight) {
      CFIndex count = CTTypesetterSuggestLineBreak(typesetter, start, lineWidth);
      
      CFArrayAppendValue(mutableLines, CTLineCreateWithAttributedString(CFAttributedStringCreateWithSubstring(NULL, (__bridge CFAttributedStringRef)(stringToDraw), CFRangeMake(start, count))));
      lineOrigins[lineCount] = CGPointMake(0, height);
      
      height += DUX_LINE_HEIGHT;
      start += count;
      lineCount++;
    }
    lines = CFArrayCreateCopy(NULL, mutableLines);
    [self setNeedsDisplay];
  } else { // changed origin only.
    height = self.frame.size.height;
  }
  
  [super setFrame:CGRectMake(point.x, point.y - height, width, height)];
}

- (void)createStringToDraw
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
  
  NSRange stringToDrawRange = NSMakeRange(self.range.location, MIN(self.range.length, DUX_LINE_MAX_STRING_TO_DRAW_LENGTH));
  if (self.range.length > 0) {
    stringToDraw = [[NSMutableAttributedString alloc] initWithString:[self.storage.string substringWithRange:stringToDrawRange] attributes:attributes];
  } else {
    stringToDraw = [[NSMutableAttributedString alloc] initWithString:@" " attributes:attributes]; // empty line has zero height, so we force a space
  }
  
  // apply syntax colors
  for (NSDictionary *elementRecord in self.elements) {
    NSRange elementRange = NSMakeRange([[elementRecord valueForKey:@"start"] unsignedIntegerValue], [[elementRecord valueForKey:@"length"] unsignedIntegerValue]);
    if (elementRange.location >= stringToDrawRange.length)
      break;
    
    if (elementRange.location + elementRange.length > stringToDrawRange.length)
      elementRange.length = stringToDrawRange.length - elementRange.location;
    if (elementRange.length == 0)
      break;
    
    [stringToDraw addAttribute:NSForegroundColorAttributeName value:(id)[[elementRecord valueForKey:@"element"] color].CGColor range:elementRange];
  }
}

- (CGPoint)pointForCharacterOffset:(NSUInteger)characterOffset
{
  if (!lines) {
    [NSException raise:@"Called Too Early" format:@"%s cannot be called when line metrix haven't been calculated yet. setFrame: must be called before pointForCharacterOffset:", __PRETTY_FUNCTION__];
    return NSMakePoint(FLT_MAX, FLT_MAX);
  }
  
  if (characterOffset == self.range.location)
    return CGPointMake(DUX_LINE_NUMBER_WIDTH, 0);
  
  CFIndex lineIndex;
  for (lineIndex = 0; lineIndex < lineCount; lineIndex++) {
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    CFRange lineRange = CTLineGetStringRange(line);
    
    
    
    if (self.range.location + lineRange.location + lineRange.length >= characterOffset) {
      CGFloat characterX = CTLineGetOffsetForStringIndex(line, characterOffset - self.range.location, NULL);
      
      CGPoint point = CGPointMake(DUX_LINE_NUMBER_WIDTH + lineOrigins[lineIndex].x + characterX,
                                  lineOrigins[lineIndex].y - 4);
      
      return point;
    }
  }
  
  [NSException raise:@"Illegal Offset" format:@"%s offset %lu is outside the bounds of line (%@).", __PRETTY_FUNCTION__, characterOffset, self];
  return NSMakePoint(FLT_MAX, FLT_MAX);
}

- (NSUInteger)characterOffsetForPoint:(CGPoint)point
{
  CFIndex lineIndex;
  for (lineIndex = 0; lineIndex < lineCount; lineIndex++) {
    CGPoint lineOrigin = lineOrigins[lineIndex];
    if ((lineOrigin.y - 4) > point.y) {
      continue;
    }
    
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    
    CGPoint linePoint = point;
    linePoint.x -= lineOrigin.x + DUX_LINE_NUMBER_WIDTH;
    linePoint.y = 0; // we already decided we want this line, only care about x coord
    
    CFIndex lineCharIndex = CTLineGetStringIndexForPosition(line, linePoint);
    return self.range.location + lineCharIndex;
  }
  
  return self.range.location + self.range.length;
}

- (void)drawInContext:(CGContextRef)context
{
  CGColorRef bgColor = [NSColor whiteColor].CGColor;
  CGContextSetFillColorWithColor(context, bgColor);
  CGContextFillRect(context, self.bounds);
  
  // Draw lines
  CGContextSaveGState(context);
  CGContextTranslateCTM(context, DUX_LINE_NUMBER_WIDTH, 0);
  
  CFIndex lineIndex;
  CGFloat frameHeight = self.frame.size.height;
  for (lineIndex = 0; lineIndex < lineCount; lineIndex++) {
    CGPoint lineOrigin = lineOrigins[lineIndex];
    lineOrigin.y = (frameHeight - ((lineIndex + 1) * DUX_LINE_HEIGHT)) + 4;
    
    if (lineIndex == DUX_LINE_MAX_WRAPPED_LINES) {
      NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle alloc] init] mutableCopy];
      [paragraphStyle setAlignment:NSCenterTextAlignment];
      
      NSDictionary *errorAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:@"Source Code Pro" size:10], NSFontAttributeName,
                                       [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1].CGColor, NSForegroundColorAttributeName,
                                       paragraphStyle, NSParagraphStyleAttributeName,
                                       nil];
      
      NSAttributedString *lineNumberString = [[NSAttributedString alloc] initWithString:@"!! MAX LINE LENGTH EXCEEDED !!" attributes:errorAttributes]; // empty line has zero height, so we force a space
      CTFramesetterRef lineNumberFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)lineNumberString);
      
      NSRect lineRect = NSMakeRect(lineOrigin.x, lineOrigin.y, self.bounds.size.width - lineOrigin.x, 14);
      CGContextSetRGBFillColor(context, 1, 0, 0, 1);
      CGContextFillRect(context, lineRect);
      
      CGPathRef lineNumberPath = CGPathCreateWithRect(lineRect, NULL);
      CTFrameRef lineNumberFrame = CTFramesetterCreateFrame(lineNumberFramesetter, CFRangeMake(0, 0), lineNumberPath, NULL);
      CTFrameDraw(lineNumberFrame, context);
      CFRelease(lineNumberPath);
      break;
    }
    
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
    
    CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
    CTLineDraw(line, context);
    
  }
  
  CGContextRestoreGState(context);
  
  // draw line number
  if (self.lineNumber != NSUIntegerMax) {
    NSAttributedString *lineNumberString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu", self.lineNumber] attributes:lineNumberAttributes]; // empty line has zero height, so we force a space
    CTFramesetterRef lineNumberFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)lineNumberString);
    
    NSRect lineRect = self.bounds;
    lineRect.origin.y -= 2;
    lineRect.size.width = DUX_LINE_NUMBER_WIDTH - 10;
    CGPathRef lineNumberPath = CGPathCreateWithRect(lineRect, NULL);
    CTFrameRef lineNumberFrame = CTFramesetterCreateFrame(lineNumberFramesetter, CFRangeMake(0, 0), lineNumberPath, NULL);
    CTFrameDraw(lineNumberFrame, context);
    CFRelease(lineNumberPath);
  }
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<DuxLine %lu,%lu>: \"%@\"", (unsigned long)self.range.location, (unsigned long)self.range.length, [self.storage.string substringWithRange:self.range]];
}

@end
