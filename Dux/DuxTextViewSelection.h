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

#import <AppKit/AppKit.h>

@class DuxTextView;

@interface DuxTextViewSelection : NSObject

@property (nonatomic) NSRange range;
@property (weak) DuxTextView *view;

@property (readonly) CALayer *layer;
@property (readonly) BOOL zeroLength; // returns true if range.length == 0
@property (readonly) NSUInteger maxRange; // NSMaxRange(self.range)

+ (id)selectionWithRange:(NSRange)range inTextView:(DuxTextView *)view;

- (id)initWithRange:(NSRange)range inTextView:(DuxTextView *)view; // designated

- (void)updateLayer; // make sure the layer is in the right position and on top of other layers

@end
