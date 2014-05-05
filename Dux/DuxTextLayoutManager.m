//
//  DuxTextLayoutManager.m
//  Dux
//
//  Created by Abhi Beckert on 21/04/2014.
//
//

#import "DuxTextLayoutManager.h"

@interface DuxTextLayoutManager ()

@property DuxTextStorage *storage;

@end

@implementation DuxTextLayoutManager

- (instancetype)initWithStorage:(DuxTextStorage *)storage
{
  if (!(self = [super init]))
    return nil;
  
  self.storage = storage;
  
  return self;
}

- (void)documentVisibleRectDidChange:(NSRect)newVisibleRect scrollDelta:(CGFloat)scrollDelta scrollByteOffset:(NSUInteger)scrollByteOffset contentHeight:(CGFloat)contentHeight withCallback:(void (^)(CGFloat scrollDelta, NSUInteger scrollByteOffset, CGFloat estimatedContentHeight))callback
{
  // find all the lines that should be visible TODO: this needs to use the existing set of line layers as a starting point, and only ask the storage for lines that we don't already have
  CGFloat yFromTop = scrollDelta;
  
  NSRect visibleRect = newVisibleRect;
  CGFloat minYFromBottom = NSMinY(visibleRect) - 5000;
  minYFromBottom += DUX_LINE_HEIGHT - ((NSUInteger)minYFromBottom % DUX_LINE_HEIGHT); // round to next line increment
  if (minYFromBottom < 0)
    minYFromBottom = 0;
  
  CGFloat maxYFromBottom = NSMaxY(visibleRect) + DUX_LINE_HEIGHT + 5000;
  maxYFromBottom += DUX_LINE_HEIGHT - ((NSUInteger)maxYFromBottom % DUX_LINE_HEIGHT); // round to next line increment
  if (maxYFromBottom > contentHeight)
    maxYFromBottom = contentHeight;
  
  NSRange renderedByteRange = NSMakeRange(NSNotFound, NSNotFound);
  NSRange renderedPixelRange = NSMakeRange(NSNotFound, NSNotFound);
  
  DuxLine *line = [self.storage lineStartingAtByteLocation:scrollByteOffset];
  
  CGFloat yFromBottom = contentHeight - yFromTop;
  while (yFromBottom < (maxYFromBottom - 0.1)) {
    line = [self.storage lineBeforeLine:line];
    if (!line)
      break;
    
    yFromTop -= DUX_LINE_HEIGHT;
    yFromTop = round(yFromTop);
    yFromBottom = contentHeight - yFromTop;
    
    scrollByteOffset = line.range.location;
    scrollDelta = yFromTop;
  }
  
  BOOL lastLineRendered = NO;
  while (true) {
    yFromBottom = contentHeight - yFromTop;
    
    if (renderedByteRange.location == NSNotFound || line.range.location < renderedByteRange.location) {
      renderedByteRange.location = line.range.location;
      renderedPixelRange.location = yFromTop;
    }
    if (renderedByteRange.length == NSNotFound || NSMaxRange(line.range) > NSMaxRange(renderedByteRange)) {
      renderedByteRange.length = NSMaxRange(line.range) - renderedByteRange.location;
      renderedPixelRange.length = (yFromTop + DUX_LINE_HEIGHT) - renderedPixelRange.location;
    }
    
    if (yFromBottom > minYFromBottom && yFromBottom < maxYFromBottom) {
      lastLineRendered = YES;
    } else {
      if (lastLineRendered) { // run out of visible lines. stop now
        break;
      }
    }
    
    yFromTop += DUX_LINE_HEIGHT;
    yFromTop = round(yFromTop);
    
    line = [self.storage lineAfterLine:line];
    if (!line)
      break;
  }
  if (renderedByteRange.location == NSNotFound) {
    NSLog(@"no visible lines!");
    return;
  }
  
  CGFloat bytesToPixelRatio = (CGFloat)renderedPixelRange.length / (CGFloat)renderedByteRange.length; // average number of bytes per vertical pixel
  CGFloat estimatedHeight = round(self.storage.length * bytesToPixelRatio);
  estimatedHeight += DUX_LINE_HEIGHT - ((NSUInteger)estimatedHeight % DUX_LINE_HEIGHT); // round to next line increment
  
  callback(scrollDelta, scrollByteOffset, estimatedHeight);
}

@end
