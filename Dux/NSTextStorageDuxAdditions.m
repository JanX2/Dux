//
//  NSTextStorageDuxAdditions.m
//  Dux
//
//  Created by Chen Hongzhi on 2/25/14.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <objc/runtime.h>
#import "NSTextStorageDuxAdditions.h"

static char const * const kUsedForDuxTextView = "UsedForDuxTextView";

static void DuxSwizzle(Class cls, SEL orig, SEL new) {
  Method origMethod = class_getInstanceMethod(cls, orig);
  Method newMethod = class_getInstanceMethod(cls, new);
  
  if (class_addMethod(cls, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
    class_replaceMethod(cls, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
  } else {
    method_exchangeImplementations(origMethod, newMethod);
  }
}

@implementation NSTextStorage (NSTextStorageDuxAdditions)

+ (void)load
{
  DuxSwizzle([NSTextStorage class], @selector(nextWordFromIndex:forward:), @selector(dux_nextWordFromIndex:forward:));
  DuxSwizzle([NSTextStorage class], @selector(doubleClickAtIndex:), @selector(dux_doubleClickAtIndex:));
}

- (BOOL)usedForDuxTextView
{
  return [objc_getAssociatedObject(self, kUsedForDuxTextView) boolValue];
}

- (void)setUsedForDuxTextView:(BOOL)flag
{
  objc_setAssociatedObject(self, kUsedForDuxTextView, @(flag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)dux_nextWordFromIndex:(NSUInteger)index forward:(BOOL)flag
{
  NSUInteger boundary = [self dux_nextWordFromIndex:index forward:flag];
  
  if (!self.usedForDuxTextView) {
    return boundary;
  }
  
  if (!flag) {
    NSString *pattern = @"(\\s{2,}|[[:punct:]]{2,}(?:\\s(?!\\s))?|[[:punct:]](?:\\s(?!\\s))?)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSArray *matches = [expression matchesInString:self.string options:0 range:NSMakeRange(boundary, index - boundary)];
    
    if (matches.count > 0) {
      NSRange range  = [matches.lastObject range];
      
      if (range.length == 1 && NSMaxRange(range) == index) {
        if (matches.count == 1) {
          range = NSMakeRange(boundary, index - boundary);
        } else {
          range = [matches[matches.count - 2] range];
        }
      }
      
      if (NSMaxRange(range) == index) {
        boundary = range.location;
      } else {
        boundary = NSMaxRange(range);
      }
    }
  } else {
    NSString *pattern = @"(\\s{2,}|(?:(?<![ \\t])[ \\t])?[[:punct:]]{2,}|(?:(?<![ \\t])[ \\t])?[[:punct:]])";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSArray *matches = [expression matchesInString:self.string options:0 range:NSMakeRange(index, boundary - index)];
    
    if (matches.count > 0) {
      NSRange range = [matches[0] range];
      
      if (range.length == 1 && range.location == index) {
        if (matches.count == 1) {
          range = NSMakeRange(index, boundary - index);
        } else {
          range = [matches[1] range];
        }
      }
      
      if (range.location == index) {
        boundary = NSMaxRange(range);
      } else {
        boundary = range.location;
      }
    }
  }
  
  return boundary;
}

- (NSRange)dux_doubleClickAtIndex:(NSUInteger)location
{
  if (location > self.string.length || !self.usedForDuxTextView) {
    return [self dux_doubleClickAtIndex:location];
  }
  
  NSRange doubleRange = [self dux_doubleClickAtIndex:location];
  NSRange searchRange = NSMakeRange(doubleRange.location, location - doubleRange.location);
  NSRange leftDotRange = [self.string rangeOfString:@"." options:NSLiteralSearch|NSBackwardsSearch range:searchRange];
  searchRange = NSMakeRange(location, NSMaxRange(doubleRange) - location);;
  NSRange rightDotRange = [self.string rangeOfString:@"." options:NSLiteralSearch range:searchRange];
  
  if (leftDotRange.location == NSNotFound) {
    leftDotRange.location = doubleRange.location;
  } else {
    leftDotRange.location++;
  }
  
  if (rightDotRange.location == NSNotFound) {
    rightDotRange.location = NSMaxRange(doubleRange);
  } else if (rightDotRange.location == location) {
    return NSMakeRange(location, 1);
  }
  
  return NSMakeRange(leftDotRange.location, rightDotRange.location - leftDotRange.location);
}

@end
