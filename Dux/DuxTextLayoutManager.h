//
//  DuxTextLayoutManager.h
//  Dux
//
//  Created by Abhi Beckert on 21/04/2014.
//
//

#import <Foundation/Foundation.h>
#import "DuxLine.h"
#import "DuxTextStorage.h"

@interface DuxTextLayoutManager : NSObject

@property (readonly) DuxTextStorage *storage;

- (instancetype)initWithStorage:(DuxTextStorage *)storage;

- (void)documentVisibleRectDidChange:(NSRect)newVisibleRect scrollDelta:(CGFloat)scrollDelta scrollByteOffset:(NSUInteger)scrollByteOffset contentHeight:(CGFloat)contentHeight withCallback:(void (^)(CGFloat scrollDelta, NSUInteger scrollByteOffset, CGFloat estimatedContentHeight))callback;

@end
