//
//  DuxTextViewSelection.h
//  Dux
//
//  Created by Abhi Beckert on 2013-5-22.
//
//

//
// represents a selected range or insertion point in a text view
//

#import <Foundation/Foundation.h>

@class DuxTextView;

@interface DuxTextViewSelection : NSObject

@property NSRange range;
@property (weak) DuxTextView *view;

@property (readonly) CALayer *layer;
@property (readonly) BOOL zeroLength; // returns true if range.length == 0
@property (readonly) NSUInteger maxRange; // NSMaxRange(self.range)

+ (id)selectionWithRange:(NSRange)range inTextView:(DuxTextView *)view;

- (id)initWithRange:(NSRange)range inTextView:(DuxTextView *)view; // designated

@end
