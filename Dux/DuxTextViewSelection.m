//
//  DuxTextViewSelection.m
//  Dux
//
//  Created by Abhi Beckert on 2013-5-22.
//
//

#import "DuxTextViewSelection.h"
#import "DuxTextView.h"
#import "DuxLine.h"

@interface DuxTextViewSelection () {
  CALayer *layer;
}

@end

@implementation DuxTextViewSelection

+ (id)selectionWithRange:(NSRange)range inTextView:(DuxTextView *)view
{
  return [[[self class] alloc] initWithRange:range inTextView:view];
}

- (id)initWithRange:(NSRange)range inTextView:(DuxTextView *)view
{
  if (!(self = [super init]))
    return nil;
  
  self.range = range;
  self.view = view;
  
  return self;
}

- (void)setRange:(NSRange)range
{
  if (!layer) {
    _range = range;
    return;
  }
  
  if (_range.length != range.length) {
    if (range.length == 0) {
      DuxLine *insertionPointLine = [self.view.storage lineAtCharacterPosition:range.location];
      CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:range.location];
      
      layer.frame = CGRectMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
                               insertionPointLine.frame.origin.y + insertionPoint.y,
                               2,
                               17);
      layer.backgroundColor = CGColorCreateGenericRGB(0.11, 0.36, 0.93, 1.0);
    } else {
      DuxLine *startPointLine = [self.view.storage lineAtCharacterPosition:range.location];
      CGPoint startPoint = [startPointLine pointForCharacterOffset:range.location];
      DuxLine *endPointLine = [self.view.storage lineAtCharacterPosition:range.location + range.length];
      CGPoint endPoint = [endPointLine pointForCharacterOffset:range.location + range.length];
      
      layer.frame = CGRectMake(round(startPointLine.frame.origin.x + startPoint.x),
                               startPointLine.frame.origin.y + startPoint.y,
                               round(endPoint.x - startPoint.x),
                               17);
      layer.backgroundColor = [NSColor selectedTextBackgroundColor].CGColor;
      [layer removeAnimationForKey:@"blink"];
    }
  } else {
    DuxLine *insertionPointLine = [self.view.storage lineAtCharacterPosition:range.location];
    CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:range.location];
    CGPoint destPoint = CGPointMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
                                    insertionPointLine.frame.origin.y + insertionPoint.y);
    
    CGPoint origPoint = layer.position;
    CGPoint partialPoint;
    NSNumber *midKeyTime;
    if (fabs(origPoint.y - destPoint.y) < 0.1) { // y is the same, so accelerate x for the first 75% of animation to make it feel more responsive
      partialPoint = CGPointMake(origPoint.x + ((destPoint.x - origPoint.x) * 0.7), destPoint.y);
      midKeyTime = @0.15;
    } else if (fabs(origPoint.x - destPoint.x) < 0.1) { // x is the same, so accelerate y for the first 75% of animation to make it feel more responsive
      partialPoint = CGPointMake(destPoint.x, origPoint.y + ((destPoint.y - origPoint.y) * 0.7));
      midKeyTime = @0.15;
    } else { // linear x and y movement (make it move in a straight line diagonally)
      partialPoint = CGPointMake(origPoint.x + ((destPoint.x - origPoint.x) * 0.5), origPoint.y + ((destPoint.y - origPoint.y) * 0.5));
      midKeyTime = @0.5;
    }
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.values = @[[NSValue valueWithPoint:(NSPoint)origPoint], [NSValue valueWithPoint:(NSPoint)partialPoint], [NSValue valueWithPoint:(NSPoint)destPoint]];
    animation.keyTimes = @[@0.0, midKeyTime, @1.0];
    animation.duration = 0.1;
    
    layer.position = destPoint;
    [layer addAnimation:animation forKey:@"position"];
  }

  _range = range;
  [self.view pauseInsertionPointBlinking];
}

- (CALayer *)layer
{
  if (layer)
    return layer;
  
  layer = [[CALayer alloc] init];
  layer.anchorPoint = CGPointMake(0, 0);
  layer.autoresizingMask = kCALayerMinYMargin | kCALayerMaxXMargin;
  layer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
  
  if (self.range.length == 0) {
    DuxLine *insertionPointLine = [self.view.storage lineAtCharacterPosition:self.range.location];
    CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:self.range.location];
    
    layer.frame = CGRectMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
                             insertionPointLine.frame.origin.y + insertionPoint.y,
                             2,
                             17);
    layer.backgroundColor = CGColorCreateGenericRGB(0.11, 0.36, 0.93, 1.0);
    layer.compositingFilter = [CIFilter filterWithName:@"CIMultiplyBlendMode"];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.values = @[@0.0, @1.0];
    animation.keyTimes = @[@0.0, @1.0];
    animation.duration = 0.25;
    
    [layer addAnimation:animation forKey:@"opacity"];
  } else {
    DuxLine *startPointLine = [self.view.storage lineAtCharacterPosition:self.range.location];
    CGPoint startPoint = [startPointLine pointForCharacterOffset:self.range.location];
    DuxLine *endPointLine = [self.view.storage lineAtCharacterPosition:self.range.location + self.range.length];
    CGPoint endPoint = [endPointLine pointForCharacterOffset:self.range.location + self.range.length];
    
    layer.frame = CGRectMake(round(startPointLine.frame.origin.x + startPoint.x),
                             startPointLine.frame.origin.y + startPoint.y,
                             round(endPoint.x - startPoint.x),
                             17);
    layer.backgroundColor = [NSColor selectedTextBackgroundColor].CGColor;
    layer.compositingFilter = [CIFilter filterWithName:@"CIMultiplyBlendMode"];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.values = @[@0.0, @1.0];
    animation.keyTimes = @[@0.0, @1.0];
    animation.duration = 0.25;
    
    [layer addAnimation:animation forKey:@"opacity"];
  }
  
  return layer;
}

- (void)updateLayer
{
  if (!layer) {
    [self.view.layer addSublayer:self.layer];
    return;
  }
    
  if (self.range.length == 0) {
    DuxLine *insertionPointLine = [self.view.storage lineAtCharacterPosition:self.range.location];
    CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:self.range.location];
    
    layer.frame = CGRectMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
                             insertionPointLine.frame.origin.y + insertionPoint.y,
                             2,
                             17);
    layer.backgroundColor = CGColorCreateGenericRGB(0.11, 0.36, 0.93, 1.0);
  } else {
    DuxLine *startPointLine = [self.view.storage lineAtCharacterPosition:self.range.location];
    CGPoint startPoint = [startPointLine pointForCharacterOffset:self.range.location];
    DuxLine *endPointLine = [self.view.storage lineAtCharacterPosition:self.range.location + self.range.length];
    CGPoint endPoint = [endPointLine pointForCharacterOffset:self.range.location + self.range.length];
    
    layer.frame = CGRectMake(round(startPointLine.frame.origin.x + startPoint.x),
                             startPointLine.frame.origin.y + startPoint.y,
                             round(endPoint.x - startPoint.x),
                             17);
    layer.backgroundColor = [NSColor selectedTextBackgroundColor].CGColor;
  }
  
  [self.view.layer addSublayer:layer];
}

- (BOOL)zeroLength
{
  return (_range.length == 0);
}

- (NSUInteger)maxRange
{
  return _range.location + _range.length;
}

@end
