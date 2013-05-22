//
//  DuxTextViewSelection.m
//  Dux
//
//  Created by Abhi Beckert on 2013-5-22.
//
//

#import "DuxTextViewSelection.h"
#import "DuxTextView.h"

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

- (CALayer *)layer
{
  NSLog(@"not yet implemented %s", __PRETTY_FUNCTION__);
  
  return nil;
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
