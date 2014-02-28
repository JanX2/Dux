//
//  DuxTextView.m
//  Dux
//
//  Created by Abhi Beckert on 2011-10-20.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxTextView.h"
#import "MyTextDocument.h"
#import "DuxTextContainer.h"
#import "DuxLineNumberString.h"
#import "DuxScrollViewAnimation.h"
#import "DuxPreferences.h"
#import "DuxBundle.h"
#import "DuxLine.h"
#import "DuxTextViewSelection.h"

static CGFloat leftGutter = 4;
static CGFloat rightGutter = 4;

static CAKeyframeAnimation *insertionPointBlinkAnimation;

@interface DuxTextView()

@property NSDate *dateToResumeInsertionPointBlinking;

@property (readwrite,nonatomic) NSArray *selections;
@property (readwrite) NSArray *selectionLayers;
@property (readwrite) NSSelectionAffinity selectionAffinity;

@end

@implementation DuxTextView

static NSCharacterSet *newlineCharacterSet;
static CGFloat mainScreenBackingScaleFactor;

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mainScreenBackingScaleFactor = [NSScreen mainScreen].backingScaleFactor;
    
    newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
    
    insertionPointBlinkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    insertionPointBlinkAnimation.values = @[@1.0, @0.8, @0.1, @1.0];     // opacity at each keyframe
    insertionPointBlinkAnimation.keyTimes = @[@0.0, @0.3, @0.9, @1.0];  // percentage through the animation for each keyframe
    insertionPointBlinkAnimation.duration = 0.9;
    insertionPointBlinkAnimation.repeatCount = HUGE_VALF;
  });
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if (!(self = [super initWithCoder:aDecoder]))
    return nil;
  
  self.storage = [[DuxTextStorage alloc] init];
  [self initDuxTextView];
  
  return self;
}

- (id)initWithFrame:(NSRect)frameRect storage:(DuxTextStorage *)storage
{
  if (!(self = [super initWithFrame:frameRect]))
    return nil;
  
  self.storage = storage;
  [self initDuxTextView];
  
  return self;
}

- (void)initDuxTextView
{
  self.scrollPosition = 0;
  self.selectionLayers = @[];
  self.selectionAffinity = NSSelectionAffinityDownstream;
//  self.selections = @[[DuxTextViewSelection selectionWithRange:NSMakeRange(0, 0) inTextView:self]];
  
  self.wantsLayer = YES;
  self.layerUsesCoreImageFilters = YES;
  self.layer.backgroundColor = CGColorCreateGenericGray(1, 1);
  self.layer.contentsScale = mainScreenBackingScaleFactor;
  [self.layer setNeedsDisplay];
    
  self.showLineNumbers = [DuxPreferences showLineNumbers];
  self.showPageGuide = [DuxPreferences showPageGuide];
  self.pageGuidePosition = [DuxPreferences pageGuidePosition];
  
  DuxTextContainer *container = [[DuxTextContainer alloc] init];
  container.leftGutterWidth = self.showLineNumbers ? 34 : 0;
  container.widthTracksTextView = YES;
  
  // register for some preferences
  NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
  [notifCenter addObserver:self selector:@selector(editorFontDidChange:) name:DuxPreferencesEditorFontDidChangeNotification object:nil];
  [notifCenter addObserver:self selector:@selector(showLineNumbersDidChange:) name:DuxPreferencesShowLineNumbersDidChangeNotification object:nil];
  [notifCenter addObserver:self selector:@selector(showPageGuideDidChange:) name:DuxPreferencesShowPageGuideDidChangeNotification object:nil];
	[notifCenter addObserver:self selector:@selector(showOtherInstancesOfSelectedSymbolDidChange:) name:DuxPreferencesShowOtherInstancesOfSelectedSymbolDidChangeNotification object:nil];
  [notifCenter addObserver:self selector:@selector(pageGuidePositionDidChange:) name:DuxPreferencesPageGuidePositionDidChangeNotification object:nil];
	[notifCenter addObserver:self selector:@selector(editorTabWidthDidChange:) name:DuxPreferencesTabWidthDidChangeNotification object:nil];
	[notifCenter addObserver:self selector:@selector(textContainerSizeDidChange:) name:DuxTextContainerSizeDidChangeNotification object:container];
}

- (NSPoint)textContainerOrigin
{
//  DuxTextContainer *container = (id)self.textContainer;
//  if (![container isKindOfClass:[DuxTextContainer class]]) // this means the text view isn't yet fully setup
//    return [super textContainerOrigin];
//  
  return NSMakePoint(0, 0);
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)syntaxHighlighterDidFinishHighlighting:(NSNotification *)notif
{
//   if (self.textStorage.length == 0)
//     return;
//   
//   NSUInteger index = (self.selectedRange.location > 0) ? self.selectedRange.location : 0;
//   index = MIN(index, self.textStorage.length - 1);
//   [self setTypingAttributes:[self.textStorage attributesAtIndex:index effectiveRange:NULL]];
}

- (NSArray *)selectedRanges
{
  return @[];
//  NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:self.selections.count];
//  for (DuxTextViewSelection *selection in self.selections) {
//    [ranges addObject:[NSValue valueWithRange:selection.range]];
//  }
//  
//  return ranges.copy;
}

- (void)insertNewline:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  // find the start of the current line
//  NSUInteger lineStart = 0;
//  NSRange newlineRange = [self.textStorage.string rangeOfCharacterFromSet:newlineCharacterSet options:NSBackwardsSearch range:NSMakeRange(0, self.selectedRange.location)];
//  if (newlineRange.location != NSNotFound) {
//    lineStart = newlineRange.location + 1;
//  }
//  
//  // grab the whitespace
//  NSString *whitespace = @"";
//  NSRange whitespaceRange = [self.textStorage.string rangeOfString:@"^[\t ]+" options:NSRegularExpressionSearch range:NSMakeRange(lineStart, self.textStorage.length - lineStart)];
//  if (whitespaceRange.location != NSNotFound) {
//    whitespace = [self.textStorage.string substringWithRange:whitespaceRange];
//  }
//  
//  // are we about to insert a unix newline immediately after a mac newline? This will create a windows newline, which
//  // do nothing as far as the user is concerned, and we need to insert *two* unix newlines
//  if (self.textDocument.activeNewlineStyle == DuxNewlineUnix) {
//    if (self.selectedRange.location > 0 && [self.string characterAtIndex:self.selectedRange.location - 1] == '\r') {
//      [self insertText:[NSString stringForNewlineStyle:self.textDocument.activeNewlineStyle]];
//    }
//  }
//  
//  // insert newline
//  [self insertText:[NSString stringForNewlineStyle:self.textDocument.activeNewlineStyle]];
//  
//  // insert whitespace
//  if (whitespace) {
//    [self insertText:whitespace];
//  }
}

- (void)deleteBackward:(id)sender
{
  //  // when deleting in leading whitespace, indent left instead
  //	if ([self insertionPointInLeadingWhitespace] && [self.string beginingOfLineAtOffset:self.selectedRange.location] != self.selectedRange.location) {
  //		[self shiftSelectionLeft:self];
  //		return;
  //  }
  
  NSInteger rangeLocationDelta = 0;
  for (DuxTextViewSelection *selection in self.selections) {
    NSRange range = selection.range;
    
    if (range.location >= (0 - rangeLocationDelta)) {
      range.location += rangeLocationDelta;
    } else {
      range.location = 0;
    }
    
    if (range.length == 0) {
      if (range.location == 0)
        continue;
      
      range.location--;
      range.length = 1;
      if ([self.storage positionSplitsWindowsNewline:range.location]) {
        range.location--;
        range.length++;
      }
    }
    
    [self.storage replaceCharactersInRange:range withString:@""];
    
    selection.range = NSMakeRange(range.location, 0);
    
    rangeLocationDelta += (0 - range.length);
  }
  
  [self updateLayer];
}

- (void)deleteForward:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
  //  // when deleting in leading whitespace, indent left instead
  //	if ([self insertionPointInLeadingWhitespace] && [self.string beginingOfLineAtOffset:self.selectedRange.location] != self.selectedRange.location) {
  //		[self shiftSelectionLeft:self];
  //		return;
  //  }
//  
//  if (self.insertionPointOffset == 0) {
//    NSBeep();
//    return;
//  }
//  
//  NSRange deleteRange = NSMakeRange(self.insertionPointOffset, 1);
//  if ([self.storage positionSplitsWindowsNewline:NSMaxRange(deleteRange)]) {
//    deleteRange.length++;
//  }
//  
//  [self.storage replaceCharactersInRange:deleteRange withString:@""];
//  [self updateLayer];
}

- (IBAction)jumpToLine:(id)sender
{
  if (!self.goToLinePanel) {
    [NSBundle loadNibNamed:@"JumpToLinePanel" owner:self];
  }
  
  [self.goToLinePanel makeKeyAndOrderFront:sender];
  [self.goToLineSearchField becomeFirstResponder];
}

- (IBAction)goToLinePanelButtonClicked:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  // figure out what line we are navigating to
//  NSInteger targetLine = self.goToLineSearchField.integerValue;
//  if (!targetLine) {
//    NSBeep();
//    return;
//  }
//  
//  // find the line
//  int atLine = 1;
//  NSString *string = self.textStorage.string;
//  NSUInteger stringLength = string.length;
//  NSUInteger characterLocation = 0;
//  while (atLine < targetLine) {
//    characterLocation = [string rangeOfCharacterFromSet:newlineCharacterSet options:NSLiteralSearch range:NSMakeRange(characterLocation, (stringLength - characterLocation))].location;
//    
//    if (characterLocation == NSNotFound) {
//      NSBeep();
//      return;
//    }
//    
//    // if we are at a \r character and the next character is a \n, skip the next character
//    if (string.length >= characterLocation &&
//        [string characterAtIndex:characterLocation] == '\r' &&
//        [string characterAtIndex:characterLocation + 1] == '\n') {
//      characterLocation++;
//    }
//    
//    atLine++;
//    characterLocation++;
//  }
//  
//  // jump to the line
//  NSRange lineRange = [string rangeOfLineAtOffset:characterLocation];
//  NSUInteger glyphIndex = [self.layoutManager glyphIndexForCharacterAtIndex:lineRange.location];
//  NSRect lineRect = [self.layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:NULL];
//  
//  [DuxScrollViewAnimation animatedScrollPointToCenter:NSMakePoint(0, NSMinY(lineRect) + (NSHeight(lineRect) / 2)) inScrollView:self.enclosingScrollView];
//  
//  [self setSelectedRange:lineRange];
//  [self.goToLinePanel performClose:self];
}

- (IBAction)commentSelection:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  // get the selected range
//  NSRange commentRange = self.selectedRange;
//  
//  // if there's no selection, drop back by one character
//  if (commentRange.length == 0 && commentRange.location > 0) {
//    commentRange.location--;
//  }
//  
//  // if the last character is a newline, select one less character (this gives nicer results in most situations)
//  if (commentRange.length > 0 && [self.textStorage.string characterAtIndex:NSMaxRange(commentRange) - 1] == '\n') {
//    commentRange.length--;
//  }
//  
//  // is the *entire* selected range commented? If so, uncomment instead
//  NSRange uncommentRange;
//  if ([self.highlighter rangeIsComment:commentRange inTextStorage:self.textStorage commentRange:&uncommentRange]) {
//    
//    [self uncomment:uncommentRange];
//    return;
//  }
//  
//  // if there is no selected text, comment the whole line
//  if (commentRange.length == 0) {
//    commentRange = [self.textStorage.string rangeOfLineAtOffset:self.selectedRange.location];
//  }
//  
//  // find the language, and ask it to remove commenting
//  DuxLanguage *language = [self.highlighter languageForRange:self.selectedRange ofTextStorage:self.textStorage];
//  [language wrapCommentsAroundRange:commentRange ofTextView:self];
}

- (IBAction)uncomment:(NSRange)commentRange
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  DuxLanguage *language = [self.highlighter languageForRange:self.selectedRange ofTextStorage:self.textStorage];
//  [language removeCommentsAroundRange:commentRange ofTextView:self];
}

- (IBAction)shiftSelectionRight:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//	if ([DuxPreferences indentWidth] == 0) // indenting disabled
//		return;
//	
//  // build an array of stings that sholud be inserted
//  NSMutableArray *insertRanges = [NSMutableArray array];
//	NSMutableArray *insertStrings = [NSMutableArray array];
//  
//  for (NSValue *selectedRangeValue in self.selectedRanges) {
//    for (NSValue *lineRangeValue in [self.string lineEnumeratorForLinesInRange:selectedRangeValue.rangeValue]) {
//      NSString *whitespace = [self.string whitespaceForLineBeginingAtLocation:lineRangeValue.rangeValue.location];
//      
//      // increase the whitespace to the apropriate number of spaces
//      NSString *whitespaceChar = [DuxPreferences indentWithSpaces] ? @" " : @"\t";
//			NSUInteger targetCount = [self countSpacesInLeadingWhitespace:whitespace] + [DuxPreferences indentWidth];
//			targetCount -= targetCount % [DuxPreferences indentWidth];
//			
//      NSMutableString *newWhitespace = whitespace.mutableCopy;
//			[newWhitespace appendString:whitespaceChar];
//      while ([self countSpacesInLeadingWhitespace:newWhitespace] < targetCount) {
//        [newWhitespace appendString:whitespaceChar];
//      }
//			
//			// if we now have too many spaces, remove the last character and add spaces until we reach the right amount (possible if tabWidth is not exactly modulo indentWidth)
//			if ([self countSpacesInLeadingWhitespace:newWhitespace] != targetCount) {
//				[newWhitespace replaceCharactersInRange:NSMakeRange(newWhitespace.length - 1, 1) withString:@""];
//				while ([self countSpacesInLeadingWhitespace:newWhitespace] < targetCount) {
//					[newWhitespace appendString:@" "];
//				}
//			}
//      
//      // drop the existing whitespace from the insert string (we're done with it)
//			[newWhitespace replaceCharactersInRange:NSMakeRange(0, whitespace.length) withString:@""];
//      
//      // record it to be inserted later
//			NSRange insertRange = NSMakeRange(lineRangeValue.rangeValue.location + whitespace.length, 0);
//      [insertRanges addObject:[NSValue valueWithRange:insertRange]];
//			[insertStrings addObject:newWhitespace.copy];
//    }
//  }
//	
//	// give parent class a chance to cancel this edit, and let it do it's undo manager stuff
//	if (![self shouldChangeTextInRanges:insertRanges replacementStrings:insertStrings]) {
//		return;
//	}
//  
//  // insert the strings, maintaining the current selected range
//  NSArray *selectedRanges = self.selectedRanges;
//  
//  NSUInteger insertionOffset = 0;
//	NSUInteger insertIndex;
//  for (insertIndex = 0; insertIndex < insertRanges.count; insertIndex++) {
//    NSString *whitespace = [insertStrings objectAtIndex:insertIndex];
//		NSRange insertRange = [[insertRanges objectAtIndex:insertIndex] rangeValue];
//		insertRange.location += insertionOffset;
//    
//    [self replaceCharactersInRange:insertRange withString:whitespace];
//    
//    insertionOffset += whitespace.length;
//    
//    NSMutableArray *newSelectedRanges = [NSMutableArray array];
//    for (NSValue *selectedRangeValue in selectedRanges) {
//      NSRange selectedRange = selectedRangeValue.rangeValue;
//      
//      if (NSMaxRange(selectedRange) < insertRange.location) {
//        // selected range before insertion. do nothing
//      } else if ((selectedRange.length == 0 && selectedRange.location >= insertRange.location) || (selectedRange.length > 0 && selectedRange.location > insertRange.location)) {
//        // selected range after insertion. increase location by insertion size
//        selectedRange.location += whitespace.length;
//      } else {
//        // selected range includes insertion. extend it's length
//        selectedRange.length += whitespace.length;
//      }
//      [newSelectedRanges addObject:[NSValue valueWithRange:selectedRange]];
//    }
//    selectedRanges = [newSelectedRanges copy];
//  }
//  
//  // restore modified selected ranges
//  [self setSelectedRanges:selectedRanges];
}

- (IBAction)shiftSelectionLeft:(id)sender
{
  NSLog(@"not yet implemneted");
//	if ([DuxPreferences indentWidth] == 0) // indenting disabled
//		return;
//	
//  // build an array of stings that sholud be inserted
//	NSMutableArray *insertRanges = [NSMutableArray array];
//	NSMutableArray *insertStrings = [NSMutableArray array];
//  
//  for (NSValue *selectedRangeValue in self.selectedRanges) {
//    for (NSValue *lineRangeValue in [self.string lineEnumeratorForLinesInRange:selectedRangeValue.rangeValue]) {
//      NSString *whitespace = [self.string whitespaceForLineBeginingAtLocation:lineRangeValue.rangeValue.location];
//      
//			// figure out the apropriate indent width
//			NSUInteger targetCount = [self countSpacesInLeadingWhitespace:whitespace];
//			if (targetCount < [DuxPreferences indentWidth]) {
//				targetCount = 0;
//			} else {
//				targetCount -= [DuxPreferences indentWidth];
//			}
//			targetCount += targetCount % [DuxPreferences indentWidth];
//			
//      // reduce the whitespace to the apropriate number of spaces
//      NSMutableString *newWhitespace = whitespace.mutableCopy;
//      while ([self countSpacesInLeadingWhitespace:newWhitespace] > targetCount) {
//        [newWhitespace replaceCharactersInRange:NSMakeRange(newWhitespace.length -1, 1) withString:@""];
//      }
//			NSRange insertRange = NSMakeRange(lineRangeValue.rangeValue.location + newWhitespace.length, whitespace.length - newWhitespace.length);
//			NSString *insertString = @"";
//			
//			// if we now don't have enough spaces, add some until we have the right amount (this can happen if there's an odd combination of tabs/spaces)
//			while ([self countSpacesInLeadingWhitespace:newWhitespace] < targetCount) {
//				insertString = [insertString stringByAppendingString:@" "];
//			}
//      
//      // record it to be inserted later
//			[insertRanges addObject:[NSValue valueWithRange:insertRange]];
//			[insertStrings addObject:insertString];
//    }
//  }
//	
//	// give parent class a chance to cancel this edit, and let it do it's undo manager stuff
//	if (![self shouldChangeTextInRanges:insertRanges replacementStrings:insertStrings]) {
//		return;
//	}
//  
//  // insert the strings, maintaining the current selected range
//  NSArray *selectedRanges = self.selectedRanges;
//  
//  NSInteger insertionOffset = 0;
//	NSUInteger insertIndex;
//  for (insertIndex = 0; insertIndex < insertRanges.count; insertIndex++) {
//    NSString *whitespace = [insertStrings objectAtIndex:insertIndex];
//		NSRange insertRange = [[insertRanges objectAtIndex:insertIndex] rangeValue];
//		insertRange.location += insertionOffset;
//    
//    [self replaceCharactersInRange:insertRange withString:whitespace];
//    
//    insertionOffset -= (insertRange.length - whitespace.length);
//    
//    NSMutableArray *newSelectedRanges = [NSMutableArray array];
//    for (NSValue *selectedRangeValue in selectedRanges) {
//      NSRange selectedRange = selectedRangeValue.rangeValue;
//      
//      if (NSMaxRange(selectedRange) < insertRange.location) {
//        // selected range before insertion. do nothing
//      } else if (selectedRange.location > insertRange.location) {
//        // selected range after insertion. reduce location by insertion size
//        selectedRange.location -= (insertRange.length - whitespace.length);
//      } else {
//        // selected range includes insertion. reduce it's length
//				if (selectedRange.length > (insertRange.length - whitespace.length)) {
//					selectedRange.length -= (insertRange.length - whitespace.length);
//				} else {
//					selectedRange.length = 0;
//				}
//      }
//			
//			if (selectedRange.length > 0 || newSelectedRanges.count == 0) // can only have a single zero length range
//				[newSelectedRanges addObject:[NSValue valueWithRange:selectedRange]];
//    }
//    selectedRanges = [newSelectedRanges copy];
//  }
//  
//  // restore modified selected ranges
//  [self setSelectedRanges:selectedRanges];
}

- (void)setSelectedRanges:(NSArray *)ranges
{
  NSMutableArray *selections = [[NSMutableArray alloc] initWithCapacity:ranges.count];
  for (NSValue *rangeValue in ranges) {
    [selections addObject:[DuxTextViewSelection selectionWithRange:rangeValue.rangeValue inTextView:self]];
  }
  
  [self setSelections:selections];
}

//- (void)setSelections:(NSArray *)selections
//{
//  // check for illegal ranges
//  NSUInteger rangeCount = selections.count;
//  for (NSUInteger rangeIndex = 0; rangeIndex < rangeCount; rangeIndex++) {
//    DuxTextViewSelection *selection = [selections objectAtIndex:rangeIndex];
//    
//    if ([self.storage positionSplitsWindowsNewline:selection.range.location]) {
//      NSRange range = selection.range;
//      range.location++;
//      if (range.length > 0)
//        range.length--;
//      
//      selection.range = range;
//    }
//    
//    if ([self.storage positionSplitsWindowsNewline:selection.maxRange]) {
//      NSRange range = selection.range;
//      range.length++;
//      
//      selection.range = range;
//    }
//  }
//  
//  // sort them
//  selections = [selections sortedArrayUsingComparator:^NSComparisonResult(DuxTextViewSelection *selection1, DuxTextViewSelection *selection2) {
//    NSRange range1 = selection1.range;
//    NSRange range2 = selection2.range;
//
//    if (range1.location < range2.location) {
//      return NSOrderedAscending;
//    } else if (range1.location > range2.location) {
//      return NSOrderedDescending;
//    } else {
//      return NSOrderedSame;
//    }
//  }];
//  
//  
//  // create new selection range layers, attempting to re-use existing layers intelligently (so we can move them with animation)
////  NSMutableArray *newSelections = [[NSMutableArray alloc] initWithCapacity:selections.count];
////  NSMutableArray *selectionsNeedingLayers = selections.mutableCopy;
//  
////  NSMutableArray *reusableSelectionLayers = self.selectionLayers.mutableCopy;
////  NSMutableArray *reusableSelectionLayerRanges = [NSMutableArray arrayWithCapacity:self.selections.count];
////  for (DuxTextViewSelection *selection in self.selections) {
////    [reusableSelectionLayerRanges addObject:[NSValue valueWithRange:selection.range]];
////  }
//  
//  
//  // re-use layers that overlap the new ranges
////  for (NSUInteger rangeIndex = 0; rangeIndex < selectionsNeedingLayers.count; rangeIndex++) {
////    NSRange range = ((DuxTextViewSelection *)[selectionsNeedingLayers objectAtIndex:rangeIndex]).range;
////    
////    BOOL foundMatch = NO;
////    for (NSUInteger reusableRangeIndex = 0; reusableRangeIndex < reusableSelectionLayerRanges.count; reusableRangeIndex++) {
////      NSRange reusableRange = ((NSValue *)[reusableSelectionLayerRanges objectAtIndex:reusableRangeIndex]).rangeValue;
////      
////      
////      if (range.location >= reusableRange.location && range.location <= (reusableRange.location + reusableRange.length)) {
////        foundMatch = YES;
////      }
////      
////      if (!foundMatch && (range.location + range.length) >= reusableRange.location && (range.location + range.length) <= (reusableRange.location + reusableRange.length)) {
////        foundMatch = YES;
////      }
////      
////      if (foundMatch) {
////        NSRange oldRange = ((NSValue *)[reusableSelectionLayerRanges objectAtIndex:reusableRangeIndex]).rangeValue;
////        CALayer *layer = [reusableSelectionLayers objectAtIndex:reusableRangeIndex];
////        if (oldRange.length != range.length) {
////          if (range.length == 0) {
////            DuxLine *insertionPointLine = [self.storage lineAtCharacterPosition:range.location];
////            CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:range.location];
////            
////            layer.frame = CGRectMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
////                                     insertionPointLine.frame.origin.y + insertionPoint.y,
////                                     2,
////                                     17);
////            layer.backgroundColor = CGColorCreateGenericRGB(0.11, 0.36, 0.93, 1.0);
////          } else {
////            DuxLine *startPointLine = [self.storage lineAtCharacterPosition:range.location];
////            CGPoint startPoint = [startPointLine pointForCharacterOffset:range.location];
////            DuxLine *endPointLine = [self.storage lineAtCharacterPosition:range.location + range.length];
////            CGPoint endPoint = [endPointLine pointForCharacterOffset:range.location + range.length];
////            
////            layer.frame = CGRectMake(round(startPointLine.frame.origin.x + startPoint.x),
////                                     startPointLine.frame.origin.y + startPoint.y,
////                                     round(endPoint.x - startPoint.x),
////                                     17);
////            layer.backgroundColor = [NSColor selectedTextBackgroundColor].CGColor;
////            [layer removeAnimationForKey:@"blink"];
////          }
////        }
////        
////        [newSelections addObject:@{@"range":[NSValue valueWithRange:range], @"layer":layer}];
////        [reusableSelectionLayers removeObjectAtIndex:reusableRangeIndex];
////        [reusableSelectionLayerRanges removeObjectAtIndex:reusableRangeIndex];
////        break;
////      }
////    }
////    if (foundMatch) {
////      [selectionsNeedingLayers removeObjectAtIndex:rangeIndex];
////      rangeIndex--;
////    }
////  }
//  
//  // re-use layers that are closest to the new ranges (if two ranges are equal distance apart, slectionAffinity defines the one we use
////  for (NSUInteger rangeIndex = 0; rangeIndex < selectionsNeedingLayers.count; rangeIndex++) {
////    NSRange range = ((DuxTextViewSelection *)[selectionsNeedingLayers objectAtIndex:rangeIndex]).range;
////    
////    BOOL foundLayer = NO;
////    NSInteger closestRangeDistance = LONG_MAX;
////    NSUInteger closestRangeIndex;
////    for (NSUInteger reusableRangeIndex = 0; reusableRangeIndex < reusableSelectionLayerRanges.count; reusableRangeIndex++) {
////      NSRange reusableRange = ((NSValue *)[reusableSelectionLayerRanges objectAtIndex:reusableRangeIndex]).rangeValue;
////      
////      NSInteger distance = labs(reusableRange.location - range.location);
////      distance = MIN(distance, labs((reusableRange.location + reusableRange.length) - range.location));
////      distance = MIN(distance, labs(reusableRange.location - (range.location + reusableRange.length)));
////      distance = MIN(distance, labs((reusableRange.location + reusableRange.length) - (range.location + reusableRange.length)));
////      
////      if (self.selectionAffinity == NSSelectionAffinityDownstream && (reusableRange.location + reusableRange.length) < range.location) {
////        distance++;
////      } else if (self.selectionAffinity == NSSelectionAffinityUpstream && (reusableRange.location + reusableRange.length) > range.location) {
////        distance++;
////      }
////      
////      if (distance < closestRangeDistance) {
////        foundLayer = YES;
////        closestRangeDistance = distance;
////        closestRangeIndex = reusableRangeIndex;
////      }
////    }
////    if (foundLayer) {
////      NSRange oldRange = ((NSValue *)[reusableSelectionLayerRanges objectAtIndex:closestRangeIndex]).rangeValue;
////      CALayer *layer = [reusableSelectionLayers objectAtIndex:closestRangeIndex];
////      
////      if (oldRange.length != range.length) {
////        if (range.length == 0) {
////          DuxLine *insertionPointLine = [self.storage lineAtCharacterPosition:range.location];
////          CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:range.location];
////          
////          layer.frame = CGRectMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
////                                   insertionPointLine.frame.origin.y + insertionPoint.y,
////                                   2,
////                                   17);
////          layer.backgroundColor = CGColorCreateGenericRGB(0.11, 0.36, 0.93, 1.0);
////        } else {
////          DuxLine *startPointLine = [self.storage lineAtCharacterPosition:range.location];
////          CGPoint startPoint = [startPointLine pointForCharacterOffset:range.location];
////          DuxLine *endPointLine = [self.storage lineAtCharacterPosition:range.location + range.length];
////          CGPoint endPoint = [endPointLine pointForCharacterOffset:range.location + range.length];
////          
////          layer.frame = CGRectMake(round(startPointLine.frame.origin.x + startPoint.x),
////                                   startPointLine.frame.origin.y + startPoint.y,
////                                   round(endPoint.x - startPoint.x),
////                                   17);
////          layer.backgroundColor = [NSColor selectedTextBackgroundColor].CGColor;
////          [layer removeAnimationForKey:@"blink"];
////        }
////      } else {
////        DuxLine *insertionPointLine = [self.storage lineAtCharacterPosition:range.location];
////        CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:range.location];
////        CGPoint destPoint = CGPointMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
////                                        insertionPointLine.frame.origin.y + insertionPoint.y);
////        
////        CGPoint origPoint = layer.position;
////        CGPoint partialPoint;
////        NSNumber *midKeyTime;
////        if (fabs(origPoint.y - destPoint.y) < 0.1) { // y is the same, so accelerate x for the first 75% of animation to make it feel more responsive
////          partialPoint = CGPointMake(origPoint.x + ((destPoint.x - origPoint.x) * 0.7), destPoint.y);
////          midKeyTime = @0.15;
////        } else if (fabs(origPoint.x - destPoint.x) < 0.1) { // x is the same, so accelerate y for the first 75% of animation to make it feel more responsive
////          partialPoint = CGPointMake(destPoint.x, origPoint.y + ((destPoint.y - origPoint.y) * 0.7));
////          midKeyTime = @0.15;
////        } else { // linear x and y movement (make it move in a straight line diagonally)
////          partialPoint = CGPointMake(origPoint.x + ((destPoint.x - origPoint.x) * 0.5), origPoint.y + ((destPoint.y - origPoint.y) * 0.5));
////          midKeyTime = @0.5;
////        }
////        
////        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
////        animation.values = @[[NSValue valueWithPoint:(NSPoint)origPoint], [NSValue valueWithPoint:(NSPoint)partialPoint], [NSValue valueWithPoint:(NSPoint)destPoint]];
////        animation.keyTimes = @[@0.0, midKeyTime, @1.0];
////        animation.duration = 0.1;
////        
////        layer.position = destPoint;
////        [layer addAnimation:animation forKey:@"position"];
////      }
////      
////      [newSelections addObject:@{@"range":[NSValue valueWithRange:range], @"layer":layer}];
////      [reusableSelectionLayers removeObjectAtIndex:closestRangeIndex];
////      [reusableSelectionLayerRanges removeObjectAtIndex:closestRangeIndex];
////      
////      [selectionsNeedingLayers removeObjectAtIndex:rangeIndex];
////      rangeIndex--;
////    }
////  }
//  
//  // kill any layers we didn't re-use
//  NSArray *newSelectionLayers = [selections valueForKey:@"layer"];
//  for (CALayer *layer in self.selectionLayers) {
//    if (![newSelectionLayers containsObject:layer])
//      [layer removeFromSuperlayer];
//  }
//  
//  // insert new layers (or move them to the top)
//  for (CALayer *layer in newSelectionLayers) {
//    [self.layer addSublayer:layer];
//  }
//  
//  // update instance variables
//  _selections = selections;
//  self.selectionLayers = newSelectionLayers;
//  
//  // sort new selections
////  [newSelections sortUsingComparator:^NSComparisonResult(NSDictionary *selection1, NSDictionary *selection2) {
////    NSRange range1 = ((NSValue *)[selection1 valueForKey:@"range"]).rangeValue;
////    NSRange range2 = ((NSValue *)[selection2 valueForKey:@"range"]).rangeValue;
////    
////    if (range1.location < range2.location) {
////      return NSOrderedAscending;
////    } else if (range1.location > range2.location) {
////      return NSOrderedDescending;
////    } else {
////      return NSOrderedSame;
////    }
////  }];
////  
////  // apply the new ranges and layers
////  NSMutableArray *newTextViewSelections = [NSMutableArray arrayWithCapacity:newSelections.count];
////  for (NSDictionary *selection in newSelections) {
////    [newTextViewSelections addObject:[DuxTextViewSelection selectionWithRange:[[selection valueForKey:@"range"] rangeValue] inTextView:self]];
////  }
////  _selections = newTextViewSelections.copy;
////  _selections = newSelections.copy;
////  self.selectionLayers = [newSelections valueForKey:@"layer"];
//  
//  // pause insertion point blinking, and update layers
//  [self pauseInsertionPointBlinking];
//}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
  return @[];
//  NSTextStorage *textStorage = self.textStorage;
//  NSString *string = textStorage.string;
//  NSUInteger stringLength = string.length;
//  
//  // figure out the partial word
//  NSString *partialWord = [string substringWithRange:charRange];
//  NSString *wordPattern = [NSString stringWithFormat:@"\\b%@[a-zA-Z0-9_]+", [NSRegularExpression escapedPatternForString:partialWord]];
//  NSRegularExpression *wordExpression = [[NSRegularExpression alloc] initWithPattern:wordPattern options:0 error:NULL];
//  
//  // find every word in the current document that begins with the same string
//  NSMutableSet *completions = [NSMutableSet set];
//  __block NSString *completion;
//  [wordExpression enumerateMatchesInString:string options:0 range:NSMakeRange(0, stringLength) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
//    completion = [string substringWithRange:match.range];
//    
//    if ([completions containsObject:completion]) {
//      return;
//    }
//    
//    [completions addObject:completion];
//  }];
//  
//  return [completions sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
}

- (NSUInteger)countSpacesInLeadingWhitespace:(NSString *)lineString
{
  NSUInteger spacesWide = 0;
  NSUInteger charLocation;
  for (charLocation = 0; charLocation < lineString.length; charLocation++) {
    switch ([lineString characterAtIndex:charLocation]) {
      case ' ':
        spacesWide++;
        break;
      case '\t':
        spacesWide++;
        while (spacesWide % [DuxPreferences tabWidth] != 0) {
          spacesWide++;
        }
        break;
      default: // found a non
        charLocation = lineString.length;
    }
  }
  
  return spacesWide;
}

- (IBAction)showCompletions:(id)sender
{
  [self complete:sender];
}

- (IBAction)paste:(id)sender
{
  NSArray *copiedItems = [[NSPasteboard generalPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:[NSDictionary dictionary]];
  if (copiedItems == nil || copiedItems.count == 0) {
    NSBeep();
    return;
  }
  
  NSString *pasteString = [copiedItems objectAtIndex:0];
  pasteString = [pasteString stringByReplacingNewlinesWithNewline:self.textDocument.activeNewlineStyle];
  
  [self breakUndoCoalescing];
  [self insertText:pasteString];
  [self breakUndoCoalescing];
}

- (void)insertText:(id)insertString
{
  NSString *string = [insertString isKindOfClass:[NSAttributedString class]] ? [insertString string] : insertString;
  
  NSInteger rangeLocationDelta = 0;
  for (DuxTextViewSelection *selection in self.selections) {
    NSRange range = selection.range;
    range.location += rangeLocationDelta;
    
    [self.storage replaceCharactersInRange:range withString:string];
    
    selection.range = NSMakeRange(range.location + string.length, 0);
    
    rangeLocationDelta += (string.length - range.length);
  }
  
  [self updateLayer];
}

- (void)insertSnippet:(NSString *)snippet
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  if (snippet.length == 0)
//    return;
//  
//  NSRange selectedRangeAfterInsert = NSMakeRange(self.selectedRange.location + snippet.length, 0);
//  
//  NSRange snippetSelectedRange = [snippet rangeOfString:@"$0"];
//  if (snippetSelectedRange.location != NSNotFound) {
//    NSString *selectedString = @"";
//    if (self.selectedRange.length > 0) {
//      selectedString = [self.textStorage.string substringWithRange:self.selectedRange];
//    }
//    
//    snippet = [snippet stringByReplacingCharactersInRange:snippetSelectedRange withString:selectedString];
//    
//    selectedRangeAfterInsert = NSMakeRange(self.selectedRange.location + snippetSelectedRange.location, selectedString.length);
//  }
//  
//  
//  [self insertText:snippet];
//  self.selectedRange = selectedRangeAfterInsert;
}

- (BOOL)smartInsertDeleteEnabled
{
  return NO;
}

- (BOOL)isAutomaticQuoteSubstitutionEnabled
{
  return NO;
}

- (BOOL)isAutomaticLinkDetectionEnabled
{
  return NO;
}

- (BOOL)isAutomaticDataDetectionEnabled
{
  return NO;
}

- (BOOL)isAutomaticDashSubstitutionEnabled
{
  return NO;
}

- (BOOL)isAutomaticTextReplacementEnabled
{
  return NO;
}

- (BOOL)isAutomaticSpellingCorrectionEnabled
{
  return NO;
}

- (void)keyDown:(NSEvent *)theEvent
{
//  // handle tab completion?
//  if (([[theEvent charactersIgnoringModifiers] characterAtIndex:0] == NSTabCharacter) && self.selectedRange.length == 0 && !([theEvent modifierFlags] & NSShiftKeyMask)) {
//  
//    id target = [NSApp targetForAction:@selector(performDuxBundle:)];
//    if (target) {
//      for (NSDictionary *triggerAndBundle in [DuxBundle tabTriggerBundlesSortedByTriggerLength]) {
//        NSString *trigger = [triggerAndBundle valueForKey:@"trigger"];
//        DuxBundle *bundle = [triggerAndBundle valueForKey:@"bundle"];
//        
//        if (self.selectedRange.location < trigger.length)
//          continue;
//        
//        if ([self.textStorage.string rangeOfString:trigger options:NSLiteralSearch range:NSMakeRange(self.selectedRange.location - trigger.length, trigger.length)].location == NSNotFound)
//          continue;
//        
//        if ([target respondsToSelector:@selector(validateMenuItem:)] && ![target validateMenuItem:bundle.menuItem]) {
//          continue;
//        }
//        
//        self.selectedRange = NSMakeRange(self.selectedRange.location - trigger.length, trigger.length);
//        [self deleteBackward:self];
//        
//        [NSApp sendAction:@selector(performDuxBundle:) to:nil from:bundle.menuItem];
//        return;
//      }
//    }
//  }
//  
//
  // handle other key
  switch ([[theEvent charactersIgnoringModifiers] characterAtIndex:0]) {
    case NSLeftArrowFunctionKey:
      if (([theEvent modifierFlags] & NSControlKeyMask)) {
        if ([theEvent modifierFlags] & NSShiftKeyMask) {
          [self moveSubwordBackwardAndModifySelection:self];
        } else {
          [self moveSubwordBackward:self];
        }
      } else {
        [self moveBackward:self extendSelection:((theEvent.modifierFlags & NSShiftKeyMask) > 0)];
      }
      return;
    case NSRightArrowFunctionKey:;
      if (([theEvent modifierFlags] & NSControlKeyMask)) {
        if ([theEvent modifierFlags] & NSShiftKeyMask) {
          [self moveSubwordForwardAndModifySelection:self];
        } else {
          [self moveSubwordForward:self];
        }
      } else {
        [self moveForward:self extendSelection:((theEvent.modifierFlags & NSShiftKeyMask) > 0)];
      }
      return;
    case NSUpArrowFunctionKey:
      [self moveUp:self];
      return;
    case NSDownArrowFunctionKey:
      [self moveDown:self];
      return;
    case NSHomeFunctionKey:
      [self scrollToBeginningOfDocument:self];
      return;
    case NSEndFunctionKey:
      [self scrollToEndOfDocument:self];
      return;
    case NSPageUpFunctionKey:
      [self scrollPageUp:self];
      return;
    case NSPageDownFunctionKey:
      [self scrollPageDown:self];
      return;
    case NSDeleteCharacter: // "delete" on mac keyboards, but "backspace" on others
      if (([theEvent modifierFlags] & NSControlKeyMask)) {
        [self deleteSubwordBackward:self];
      } else {
        [self deleteBackward:self];
      }
      return;
    case NSDeleteFunctionKey: // "delete forward" on mac keyboards, but "delete" on others
      if (([theEvent modifierFlags] & NSControlKeyMask)) {
        [self deleteSubwordForward:self];
      } else {
        [self deleteForward:self];
      }
      return;
    case NSTabCharacter:
    case 25: // shift-tab
      if (![self tabShouldIndentWithCurrentSelectedRange]) {
        break;
      }
      
      if (theEvent.modifierFlags & NSShiftKeyMask) {
        [self shiftSelectionLeft:self];
      } else {
        [self shiftSelectionRight:self];
      }
      return;
  }
  
  [self insertText:theEvent.characters];
}

- (BOOL)insertionPointInLeadingWhitespace
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
  return NO;
//	if (self.selectedRanges.count > 1)
//		return NO;
//	
//  if (self.selectedRange.length != 0)
//    return NO;
//  
//  if (self.selectedRange.location == 0)
//    return YES;
//  
//  NSUInteger currentLineStart = [self.string rangeOfLineAtOffset:self.selectedRange.location].location;
//  if (currentLineStart == self.selectedRange.location)
//    return YES;
//  
//  NSCharacterSet *nonWhitespaceCharacterSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
//  NSUInteger charLocation = [self.string rangeOfCharacterFromSet:nonWhitespaceCharacterSet options:NSLiteralSearch range:NSMakeRange(currentLineStart, self.selectedRange.location - currentLineStart)].location;
//  
//  return charLocation == NSNotFound;
}

- (BOOL)tabShouldIndentWithCurrentSelectedRange
{
  if ([DuxPreferences tabIndentBehaviour] == DuxTabAlwaysIndents)
    return YES;
  
  if ([DuxPreferences tabIndentBehaviour] == DuxTabNeverIndents)
    return NO;

  return [self insertionPointInLeadingWhitespace];
}

- (NSUInteger)findBeginingOfSubwordStartingAt:(NSUInteger)offset
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
  return offset;
//  // find one of three possibilities:
//  //  - the begining of a single word, all uppercase, that is at the end of the search range (parenthesis set 2)
//  //  - a point where a non-lowercase character is followed by a lowercase character (parenthesis set 4)
//  NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"([^a-z0-9]([A-Z]+[^a-z0-9]*$))|(^|[^a-z0-9])([a-z0-9])" options:0 error:NULL];
//  
//  // we only work with one line at a time, to make the regex faster
//  NSRange lineRange = [self.textStorage.string rangeOfLineAtOffset:offset];
//  NSString *searchString = [self.textStorage.string substringWithRange:lineRange];
//  
//  // prepare search range
//  NSUInteger insertionPoint = offset - lineRange.location;
//  NSRange searchRange = NSMakeRange(0, insertionPoint);
//  
//  // we may need to try the search again on the previous line
//  NSUInteger newInsertionPoint = 0;
//  while (YES) {
//    // don't bother searching from the begining of the line... try again on the previous line (unless we are at the begining of the file!)
//    if (insertionPoint == 0 && lineRange.location != 0) {
//      lineRange = [self.textStorage.string rangeOfLineAtOffset:lineRange.location - 1];
//      searchString = [self.textStorage.string substringWithRange:lineRange];
//      insertionPoint = lineRange.length - 1;
//      searchRange = NSMakeRange(0, lineRange.length);
//      continue;
//    }
//    
//    // find the last match
//    NSTextCheckingResult *match = [[expression matchesInString:searchString options:0 range:searchRange] lastObject];
//    
//    // which match do we want?
//    newInsertionPoint = 0;
//    if (match && [match rangeAtIndex:2].location != NSNotFound) {
//      newInsertionPoint = [match rangeAtIndex:2].location;
//    } else if (match && [match rangeAtIndex:4].location != NSNotFound) {
//      newInsertionPoint = [match rangeAtIndex:4].location;
//    } else { // no match found at all, try again on the previous line
//      if (lineRange.location != 0) { // make sure we aren't at the begining of the file
//        lineRange = [self.textStorage.string rangeOfLineAtOffset:lineRange.location - 1];
//        searchString = [self.textStorage.string substringWithRange:lineRange];
//        insertionPoint = lineRange.length - 1;
//        searchRange = NSMakeRange(0, lineRange.length);
//        continue;
//      }
//    }
//    
//    // if we are in between an uppercase letter and a lowercase letter, than we need to drop 1 from the index
//    if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[searchString characterAtIndex:newInsertionPoint - 1]]) {
//      newInsertionPoint--;
//    }
//    
//    break;
//  }
//  
//  return newInsertionPoint + lineRange.location;
}

- (NSUInteger)findEndOfSubwordStartingAt:(NSUInteger)offset
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
  return offset;
//  // find one of two possibilities:
//  //  - the end of a single word, all uppercase, that is at the begining of the search range (parenthesis set 2)
//  //  - a point where a lowercase character is followed by a non-lowercase character (parenthesis set 4)
//  NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"((^[^a-z0-9]*[A-Z]+)[^A-Z])|([a-z0-9])($|[^a-z0-9])" options:0 error:NULL];
//  
//  // we only work with one line at a time, to make the regex faster
//  NSRange lineRange = [self.textStorage.string rangeOfLineAtOffset:offset];
//  NSString *searchString = [self.textStorage.string substringWithRange:lineRange];
//  
//  // prepare search range
//  NSUInteger insertionPoint = offset - lineRange.location;
//  NSRange searchRange = NSMakeRange(MIN(insertionPoint + 1, searchString.length), searchString.length == 0 ? 0 : (searchString.length - (insertionPoint + 1)));
//  
//  // we may need to try the search again on the previous line
//  NSUInteger newInsertionPoint = searchString.length;
//  while (YES) {
//    // don't bother searching from the begining of the line... try again on the next line (unless we are at the end of the file!)
//    if (insertionPoint >= (searchString.length - 1) && (NSMaxRange(lineRange) < self.textStorage.string.length)) {
//      lineRange = [self.textStorage.string rangeOfLineAtOffset:NSMaxRange(lineRange) + 1];
//      searchString = [self.textStorage.string substringWithRange:lineRange];
//      insertionPoint = 0;
//      searchRange = NSMakeRange(0, searchString.length);
//      continue;
//    }
//    
//    // find the last match
//    NSTextCheckingResult *match = [expression firstMatchInString:searchString options:0 range:searchRange];
//    
//    // which match do we want?
//    newInsertionPoint = searchString.length;
//    if (match && [match rangeAtIndex:2].location != NSNotFound) {
//      newInsertionPoint = NSMaxRange([match rangeAtIndex:2]);
//    } else if (match && [match rangeAtIndex:4].location != NSNotFound) {
//      newInsertionPoint = [match rangeAtIndex:4].location;
//    } else { // no match found at all, try again on the previous line
//      if (NSMaxRange(lineRange) < self.textStorage.string.length) { // make sure we aren't at the begining of the file
//        lineRange = [self.textStorage.string rangeOfLineAtOffset:NSMaxRange(lineRange) + 1];
//        searchString = [self.textStorage.string substringWithRange:lineRange];
//        insertionPoint = 0;
//        searchRange = NSMakeRange(0, searchString.length);
//        continue;
//      }
//    }
//    
//    // if we are in between an uppercase letter and a lowercase letter, than we need to drop 1 from the index
//    if (searchString.length > 0) {
//      BOOL prevCharIsUppercase = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[searchString characterAtIndex:newInsertionPoint - 1]];
//      BOOL nextCharIsLowercase = [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:[searchString characterAtIndex:MIN(newInsertionPoint, searchString.length - 1)]];
//      if (prevCharIsUppercase && nextCharIsLowercase) {
//        newInsertionPoint--;
//      }
//    }
//    
//    break;
//  }
//  
//  return newInsertionPoint + lineRange.location;
}

- (void)moveBackward:(id)sender extendSelection:(BOOL)extend
{
  for (DuxTextViewSelection *selection in self.selections) {
    NSRange range = selection.range;
    
    if (range.location == 0)
      continue;
    
    
    if (extend) {
      if (range.length == 0) {
        range.location--;
        range.length++;
        
        if ([self.storage positionSplitsWindowsNewline:range.location]) {
          range.location--;
          range.length++;
        }
        
        self.selectionAffinity = NSSelectionAffinityUpstream;
      } else {
        if (self.selectionAffinity == NSSelectionAffinityDownstream) {
          range.length--;
        } else {
          range.location--;
          range.length++;
          
          if ([self.storage positionSplitsWindowsNewline:range.location]) {
            range.location--;
            range.length++;
          }
        }
      }
    } else {
      if (range.length == 0) {
        range.location--;
        if ([self.storage positionSplitsWindowsNewline:range.location])
          range.location--;
      } else {
        range.length = 0;
      }
    }
    
    selection.range = range;
  }
}

- (void)moveForward:(id)sender extendSelection:(BOOL)extend
{
//  NSMutableArray *newRanges = [NSMutableArray arrayWithCapacity:self.selectedRanges.count];
//  
//  for (NSValue *rangeValue in self.selectedRanges) {
//    NSRange range = rangeValue.rangeValue;
//    
//    if (range.location + range.length == self.storage.string.length) {
//      [newRanges addObject:rangeValue];
//      continue;
//    }
//    
//    if (extend) {
//      if (range.length == 0) {
//        range.length++;
//        self.selectionAffinity = NSSelectionAffinityDownstream;
//      } else {
//        if (self.selectionAffinity == NSSelectionAffinityDownstream) {
//          range.length++;
//        } else {
//          range.location++;
//          range.length--;
//        }
//      }
//    } else {
//      if (range.length > 0) {
//        range.location = range.location + range.length;
//        range.length = 0;
//      } else {
//        range.location++;
//      }
//    }
//    
//    [newRanges addObject:[NSValue valueWithRange:range]];
//  }
//  
//  self.selectedRanges = newRanges.copy;
}

- (void)moveUp:(id)sender
{
  NSMutableArray *newRanges = [NSMutableArray arrayWithCapacity:self.selectedRanges.count];
  
  for (NSValue *rangeValue in self.selectedRanges) {
    NSRange range = rangeValue.rangeValue;
    
    DuxLine *currentLine = [self.storage lineStartingAtByteLocation:range.location];
    DuxLine *newLine = [self.storage lineBeforeLine:currentLine];

    if (!newLine){
      range.location = 0;
      range.length = 0;
    } else {
      NSUInteger columnIndex = range.location - currentLine.range.location;
      if (columnIndex > newLine.range.length)
        columnIndex = newLine.range.length;
      
      range.location = newLine.range.location + columnIndex;
      range.length = 0;
    }
    
    [newRanges addObject:[NSValue valueWithRange:range]];
  }
  
  self.selectedRanges = newRanges.copy;
}

- (void)moveDown:(id)sender
{
  NSMutableArray *newRanges = [NSMutableArray arrayWithCapacity:self.selectedRanges.count];
  
  for (NSValue *rangeValue in self.selectedRanges) {
    NSRange range = rangeValue.rangeValue;
    
    DuxLine *currentLine = [self.storage lineStartingAtByteLocation:range.location];
    DuxLine *newLine = [self.storage lineAfterLine:currentLine];
    
    if (!newLine){
      range.location = self.storage.length;
      range.length = 0;
    } else {
      
      NSUInteger columnIndex = range.location - currentLine.range.location;
      if (columnIndex > newLine.range.length)
        columnIndex = newLine.range.length;
      
      range.location = newLine.range.location + columnIndex;
      range.length = 0;
    }
    
    [newRanges addObject:[NSValue valueWithRange:range]];
  }
  
  self.selectedRanges = newRanges.copy;
}

- (void)moveToBeginningOfLine:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  DuxLine *line = [self.storage lineAtCharacterPosition:self.insertionPointOffset];
//  
//  [self pauseInsertionPointBlinking];
//  self.insertionPointOffset = line.range.location;
//  [self updateSelectionLayers];
}

- (void)moveToEndOfLine:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  DuxLine *line = [self.storage lineAtCharacterPosition:self.insertionPointOffset];
//  
//  [self pauseInsertionPointBlinking];
//  self.insertionPointOffset = NSMaxRange(line.range);
}

- (void)moveSubwordBackward:(id)sender
{
  NSMutableArray *newSelectedRanges = [NSMutableArray array];
  
  for (NSValue *rangeValue in self.selectedRanges) {
    NSUInteger newInsertionPoint = [self findBeginingOfSubwordStartingAt:rangeValue.rangeValue.location];
    
    NSRange newRange = NSMakeRange(newInsertionPoint, 0);
    
    [newSelectedRanges addObject:[NSValue valueWithRange:newRange]];
  }
  
  self.selectedRanges = newSelectedRanges.copy;
}

- (void)moveSubwordBackwardAndModifySelection:(id)sender
{
  NSMutableArray *newSelectedRanges = [NSMutableArray array];
  
  for (NSValue *rangeValue in self.selectedRanges) {
    NSUInteger newInsertionPoint = [self findBeginingOfSubwordStartingAt:rangeValue.rangeValue.location];
    
    NSRange newRange = NSMakeRange(newInsertionPoint, NSMaxRange(rangeValue.rangeValue) - newInsertionPoint);
    
    [newSelectedRanges addObject:[NSValue valueWithRange:newRange]];
  }
  
  self.selectedRanges = newSelectedRanges.copy;
}

- (void)moveSubwordForward:(id)sender
{
  NSMutableArray *newSelectedRanges = [NSMutableArray array];
  
  for (NSValue *rangeValue in self.selectedRanges) {
    NSUInteger newInsertionPoint = [self findEndOfSubwordStartingAt:NSMaxRange(rangeValue.rangeValue)];
    
    NSRange newRange = NSMakeRange(newInsertionPoint, 0);
    
    [newSelectedRanges addObject:[NSValue valueWithRange:newRange]];
  }
  
  self.selectedRanges = newSelectedRanges.copy;
}

- (void)moveSubwordForwardAndModifySelection:(id)sender
{
  NSMutableArray *newSelectedRanges = [NSMutableArray array];
  
  for (NSValue *rangeValue in self.selectedRanges) {
    NSUInteger newInsertionPoint = [self findEndOfSubwordStartingAt:NSMaxRange(rangeValue.rangeValue)];
    
    NSRange newRange = NSMakeRange(rangeValue.rangeValue.location, newInsertionPoint - rangeValue.rangeValue.location);
    
    [newSelectedRanges addObject:[NSValue valueWithRange:newRange]];
  }
  
  self.selectedRanges = newSelectedRanges.copy;
}

- (void)deleteSubwordBackward:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  if (self.selectedRanges.count > 1 || self.selectedRange.length > 0)
//    return [self deleteBackward:sender];
//  
//  NSUInteger deleteOffset = [self findBeginingOfSubwordStartingAt:self.selectedRange.location];
//  
//  NSRange newRange = NSMakeRange(deleteOffset, self.selectedRange.location - deleteOffset);
//  
//  [self insertText:@"" replacementRange:newRange];
}

- (void)deleteSubwordForward:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  if (self.selectedRanges.count > 1 || self.selectedRange.length > 0)
//    return [self deleteForward:sender];
//  
//  NSUInteger deleteOffset = [self findEndOfSubwordStartingAt:self.selectedRange.location];
//  
//  NSRange newRange = NSMakeRange(self.selectedRange.location, deleteOffset - self.selectedRange.location);
//  
//  [self insertText:@"" replacementRange:newRange];
}

- (void)delete:(id)sender
{
  [self deleteToBeginningOfLine:sender];
}

- (void)duplicate:(id)sender
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  NSArray *ranges;
//  NSRange newSelectionSubrange = NSMakeRange(NSNotFound, 0); // if NSNotFound, new selection will be the inserted text. else new selection will be a subrange of the inserted text
//  if (self.selectedRange.length == 0) {
//    NSRange lineRange = [self.string rangeOfLineAtOffset:self.selectedRange.location];
//    ranges = [NSArray arrayWithObject:[NSValue valueWithRange:lineRange]];
//    newSelectionSubrange = NSMakeRange(self.selectedRange.location - lineRange.location, 0);
//  } else {
//    ranges = self.selectedRanges;
//  }
//  
//  NSMutableArray *insertStrings = [NSMutableArray array];
//  NSMutableArray *insertRanges = [NSMutableArray array];
//  for (NSValue *rangeValue in ranges) {
//    [insertStrings addObject:[self.string substringWithRange:rangeValue.rangeValue]];
//    [insertRanges addObject:[NSValue valueWithRange:NSMakeRange(NSMaxRange(rangeValue.rangeValue), 0)]];
//  }
//  
//  // give parent class a chance to cancel this edit, and let it do it's undo manager stuff
//	if (![self shouldChangeTextInRanges:insertRanges replacementStrings:insertStrings]) {
//		return;
//	}
//  
//  // insert the strings
//  NSUInteger insertionOffset = 0;
//	NSUInteger insertIndex;
//  NSMutableArray *newSelectedRanges = [NSMutableArray array];
//  NSString *newlineString = [NSString stringForNewlineStyle:self.textDocument.activeNewlineStyle];
//  for (insertIndex = 0; insertIndex < insertRanges.count; insertIndex++) {
//    NSString *insertString = [insertStrings objectAtIndex:insertIndex];
//		NSRange insertRange = [[insertRanges objectAtIndex:insertIndex] rangeValue];
//		insertRange.location += insertionOffset;
//    
//    // if the range ends at the end of the line (or end of file), add a newline first
//    if (self.string.length == NSMaxRange(self.selectedRange) || NSMaxRange(insertRange) == [self.string endOfLineAtOffset:NSMaxRange(insertRange)]) {
//      [self replaceCharactersInRange:insertRange withString:newlineString];
//      insertRange.location += newlineString.length;
//    }
//    
//    // do the insert
//    [self replaceCharactersInRange:insertRange withString:insertString];
//    
//    // update selection
//    if (newSelectionSubrange.location == NSNotFound) {
//      [newSelectedRanges addObject:[NSValue valueWithRange:NSMakeRange(insertRange.location, insertString.length)]];
//    } else {
//      [newSelectedRanges addObject:[NSValue valueWithRange:NSMakeRange(insertRange.location + newSelectionSubrange.location, newSelectionSubrange.length)]];
//    }
//    
//    insertionOffset += insertString.length;
//  }
//  self.selectedRanges = newSelectedRanges.copy;
}

- (NSUInteger)characterPositionForPoint:(CGPoint)point
{
//  // first figure out which line we are inside
//  DuxLine *line = [self.storage lineAtCharacterPosition:self.scrollPosition];
//  
//  while (line) { // layout lines for a couple hundred extra pixels to improve animations
//    line = [self.storage lineAfterLine:line];
//
//    if (line.frame.origin.y < point.y)
//      break;
//  }
//  if (!line)
//    return self.storage.string.length; // reached the end of the file
//  
//  return [line characterOffsetForPoint:CGPointMake(point.x - line.frame.origin.x, point.y - line.frame.origin.y)];
  
  return 0;
}

- (void)updateLayer
{
  [CATransaction begin];
  [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions]; // disable all animations. for now we assume only the line positions will change (don't want to animate that). any line height changes, we will animate
  
  // find all the lines that should be visible TODO: this needs to use the existing set of line layers as a starting point, and only ask the storage for lines that we don't already have
  CGFloat lineWidth = self.frame.size.width - leftGutter - rightGutter;
  CGFloat yOffset = round(self.frame.size.height + self.scrollDelta);
  
  DuxLine *line = nil;
  
  NSMutableSet *lineLayers = [[NSMutableSet alloc] init];
  while (yOffset > (-0.1 - DUX_LINE_HEIGHT)) {
    if (!line) {
      line = [self.storage lineStartingAtByteLocation:self.scrollPosition];
    } else {
      line = [self.storage lineAfterLine:line];
    }
    if (!line)
      break;
    
    [line setFrameWithTopLeftOrigin:CGPointMake(leftGutter, yOffset) width:lineWidth];
    
    [lineLayers addObject:line];
    
    yOffset -= DUX_LINE_HEIGHT;
    yOffset = round(yOffset);
  }
  
  for (CALayer *layer in self.layer.sublayers.copy) {
    if ([self.selectionLayers containsObject:layer])
      continue;
    
    if ([lineLayers containsObject:layer])
      continue;
    
    [layer removeFromSuperlayer];
  }
  
  for (CALayer *layer in lineLayers) {
    if ([self.layer.sublayers containsObject:layer])
      continue;
    
    [self.layer addSublayer:layer];
    [layer setNeedsDisplay];
  }
  
  [CATransaction commit];
  
  [self updateSelectionLayers];
}

- (void)updateSelectionLayers
{
//  for (DuxTextViewSelection *selection in self.selections) {
//    [selection updateLayer];
//  }
  return;
  
  NSUInteger selectionCount = self.selections.count;
  if (selectionCount == 0)
    return;
  
  for (NSUInteger selectionIndex = 0; selectionIndex < selectionCount; selectionIndex++) {
    DuxTextViewSelection *selection = [self.selections objectAtIndex:selectionIndex];
    NSRange range = selection.range;
    
    if (range.length == 0) {
      DuxLine *insertionPointLine = [self.storage lineStartingAtByteLocation:range.location];
      CGPoint insertionPoint = [insertionPointLine pointForCharacterOffset:range.location];
      CGPoint destPoint = CGPointMake(round(insertionPointLine.frame.origin.x + insertionPoint.x),
                                      insertionPointLine.frame.origin.y + insertionPoint.y);
      
      CGPoint origPoint = selection.layer.position;
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
      
      selection.layer.position = destPoint;
      [selection.layer addAnimation:animation forKey:@"position"];
    } else {
      /* ... */
    }
  }
  
  // make sure our selection layers are on top of everything else
  for (CALayer *layer in self.selectionLayers) {
    [self.layer addSublayer:layer];
  }
}

- (void)pauseInsertionPointBlinking // this will disable the insertion point's blinking animation for a moment, then resume it
{
//  NSUInteger selectionCount = self.selections.count;
//  if (selectionCount == 0)
//    return;
//  
//  NSTimeInterval delay = 0.4;
//  self.dateToResumeInsertionPointBlinking = [NSDate dateWithTimeIntervalSinceNow:delay];
//  
//  for (NSUInteger selectionIndex = 0; selectionIndex < selectionCount; selectionIndex++) {
//    DuxTextViewSelection *selection = [self.selections objectAtIndex:selectionIndex];
//    NSRange range = selection.range;
//    if (range.length > 0)
//      continue;
//    
//    CALayer *layer = [self.selectionLayers objectAtIndex:selectionIndex];
//    [layer removeAnimationForKey:@"blink"];
//    layer.opacity = 1.0;
//  }
//  
//  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
//  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//    if ([self.dateToResumeInsertionPointBlinking timeIntervalSinceNow] > 0.01) // make sure the delay hasn't been extended
//      return;
//    
//    NSUInteger selectionCount = self.selections.count;
//    for (NSUInteger selectionIndex = 0; selectionIndex < selectionCount; selectionIndex++) {
//      DuxTextViewSelection *selection = [self.selections objectAtIndex:selectionIndex];
//      NSRange range = selection.range;
//      if (range.length > 0)
//        continue;
//      
//      CALayer *layer = [self.selectionLayers objectAtIndex:selectionIndex];
//      [layer addAnimation:insertionPointBlinkAnimation forKey:@"blink"];
//    }
//  });
}

- (void)selectionDidChange:(NSNotification *)notif
{
  [self updateHighlightedElements];
}

- (void)textDidChange:(NSNotification *)notif
{
  [self updateHighlightedElements];
}

- (void)updateHighlightedElements
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
//  // We only do highlighting when the main thread isn't very busy dealing with user activity in our text view.
//  // By delaying this method for a short moment, and when it is run checking if this really is the most recent
//  // call, we ensure this will only happen when the user stops typing, particularly if the document is complicated
//  // and typing imposes a lot of CPU activity.
//  
//  _lastUupdateHighlightedElements++;
//  NSUInteger thisUpdate = _lastUupdateHighlightedElements;
//  
//  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.05 * NSEC_PER_SEC); // weird drawing glitches if we do this immediately
//  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//    if (thisUpdate != _lastUupdateHighlightedElements)
//      return;
//    
//    NSTextStorage *textStorage = self.textStorage;
//    
//    if (self.highlightedElements.count > 0) {
//      self.highlightedElements = [NSSet set];
//      [self setNeedsDisplay:YES];
//    }
//		
//		if (![DuxPreferences showOtherInstancesOfSelectedSymbol]) {
//			return;
//		}
//    
//    if (self.selectedRange.length != 0 || self.selectedRange.location == 0 || self.selectedRange.location > self.textStorage.length)
//      return;
//    
//    NSString *string = self.textStorage.string;
//    NSUInteger stringLength = string.length;
//    NSUInteger selectedLocation = self.selectedRange.location;
//    
//    // find the current selected element
//    NSRange elementRange;
//    DuxLanguageElement *element = [self.highlighter elementAtIndex:selectedLocation - 1 longestEffectiveRange:&elementRange inTextStorage:textStorage];
//    NSString *elementString = [self.textStorage.string substringWithRange:elementRange];
//    
//    if (!element.shouldHighlightOtherIdenticalElements) {
//      return;
//    }
//    
//    // find other identical elements
//    NSUInteger searchStart = selectedLocation > 10000 ? self.selectedRange.location - 10000 : 0;
//    NSUInteger searchEnd = MIN(selectedLocation + 10000, stringLength - 1);
//    NSRange otherElementRange;
//    DuxLanguageElement *otherElement;
//    NSMutableSet *newHighlightedElements = [NSMutableSet set];
//    while (searchStart <= searchEnd) {
//      otherElementRange = [string rangeOfString:elementString options:NSLiteralSearch range:NSMakeRange(searchStart, stringLength - searchStart)];
//      if (otherElementRange.location == NSNotFound)
//        break;
//      
//      searchStart = NSMaxRange(otherElementRange);
//      
//      otherElement = [self.highlighter elementAtIndex:otherElementRange.location longestEffectiveRange:&otherElementRange inTextStorage:textStorage];
//      if (otherElementRange.length != elementRange.length)
//        continue;
//      
//      if (otherElement != element)
//        continue;
//      
//      [newHighlightedElements addObject:[NSValue valueWithRange:otherElementRange]];
//    }
//    self.highlightedElements = newHighlightedElements.count > 1 ? [newHighlightedElements copy] : [NSSet set];
//    
//    if (self.highlightedElements.count > 0) {
//      [self setNeedsDisplay:YES];
//    }
//  });
}

- (void)editorFontDidChange:(NSNotification *)notif
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
}

- (void)editorTabWidthDidChange:(NSNotification *)notif
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
}

- (void)showPageGuideDidChange:(NSNotification *)notif
{
  self.showPageGuide = [DuxPreferences showPageGuide];
  
  [self setNeedsDisplay:YES];
}

- (void)showOtherInstancesOfSelectedSymbolDidChange:(NSNotification *)notif
{
	[self updateHighlightedElements];
}

- (void)pageGuidePositionDidChange:(NSNotification *)notif
{
  self.pageGuidePosition = [DuxPreferences pageGuidePosition];
  
  [self setNeedsDisplay:YES];
}

- (void)textContainerSizeDidChange:(NSNotification *)notif
{
  [self setNeedsDisplay:YES];
}

- (NSUndoManager *)undoManager
{
  return self.window.undoManager;
}

- (BOOL)becomeFirstResponder
{
  self.backgroundColor = [NSColor duxEditorColor];
  
  return YES;
}

- (BOOL)resignFirstResponder
{
  BOOL accept = [super resignFirstResponder];
  
  if (accept) {
    self.backgroundColor = [NSColor duxBackgroundEditorColor];
  }
  
  return accept;
}

- (void)breakUndoCoalescing
{
  NSLog(@"not yet implemented: %s", __PRETTY_FUNCTION__);
}

- (void)mouseDown:(NSEvent *)event
{
  // find the insertion point under the mouse
  NSPoint mousePoint = [self convertPoint:event.locationInWindow fromView:nil];
  NSUInteger characterOffset = [self characterPositionForPoint:mousePoint];
  
  // figure out what we should do next
  NSArray *newSelectedRanges = nil;
  if (event.modifierFlags & NSCommandKeyMask) {
    // remove existing range?
    for (NSUInteger rangeIndex = 0; rangeIndex < self.selections.count; rangeIndex++) {
      DuxTextViewSelection *selection = [self.selections objectAtIndex:rangeIndex];
      NSRange range = selection.range;
      
      if (range.location >= characterOffset && (range.location + range.length) <= characterOffset) {
        NSMutableArray *mutableSelections = self.selections.mutableCopy;
        [mutableSelections removeObjectAtIndex:rangeIndex];
        self.selections = mutableSelections.copy;
        return;
      }
    }
    
    // if didn't remove one, then add this range
    if (!newSelectedRanges) {
      self.selections = [self.selections arrayByAddingObject:[DuxTextViewSelection selectionWithRange:NSMakeRange(characterOffset, 0) inTextView:self]];
      return;
    }
  }
  
  // simply set he selected range to the clicked location
  if (self.selections.count > 0) {
    self.selections = @[[self.selections objectAtIndex:0]];
  }
  ((DuxTextViewSelection *)[self.selections objectAtIndex:0]).range = NSMakeRange(characterOffset, 0);
}

//- (BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSEventGestureAxis)axis
//{
//  return (axis == NSEventGestureAxisVertical);
//}

- (NSUInteger)maxScrollPosition
{
  CGFloat linesHeight = 0;
  DuxLine *line = self.storage.lastLine;
  while (linesHeight < (self.frame.size.height - DUX_LINE_HEIGHT)) {
    DuxLine *nextLine = [self.storage lineBeforeLine:line];
    if (!nextLine)
      break;
    
    linesHeight += DUX_LINE_HEIGHT;
    line = nextLine;
  }
  
  if (!line)
    return 0;
  
  DuxLine *nextLine = [self.storage lineAfterLine:line];
  if (nextLine)
    return nextLine.range.location;
  
  return line.range.location;
}

- (void)scrollWheel:(NSEvent *)event
{
  NSEventPhase phase = event.phase;
  if (event.momentumPhase != NSEventPhaseNone) {
    phase = event.momentumPhase;
    scrollInMomentumPhase = YES;
  } else {
    scrollInMomentumPhase = NO;
  }
  
  switch(phase) {
    case NSEventPhaseEnded:
    case NSEventPhaseCancelled: {
      if (self.scrollPosition == 0 && self.scrollDelta < 0) {
        [self scrollBy:self.scrollDelta animated:YES];
      }
      scrollInMomentumPhase = NO;
      break;
    }
    default: {
      CGFloat delta = event.scrollingDeltaY;
      if (!event.hasPreciseScrollingDeltas)
        delta *= DUX_LINE_HEIGHT;
      
      if (scrollInMomentumPhase && self.scrollPosition == 0 && self.scrollDelta - delta < 0)
        return;
      
      [self scrollBy:delta animated:(!event.hasPreciseScrollingDeltas)]; // if we have precise scroll deltas, we want to scroll instantly
    }
  }
}

- (void)scrollBy:(CGFloat)delta animated:(BOOL)animated
{
  animated = NO; // currently buggy
  
  // not going anywhere?
  if (fabs(delta) < 0.1) {
    return;
  }
  
  // convert pixel offset into our own internal representation (which is based on byte offsets in the document data)
  self.scrollDelta -= delta;
  
  // if scrollDelta is more than one line, remove the invisible lines and adjust the scroll position to the first visible line
  while (self.scrollDelta > DUX_LINE_HEIGHT) {
    DuxLine *thisLine = [self.storage lineStartingAtByteLocation:self.scrollPosition];
    DuxLine *nextLine = [self.storage lineAfterLine:thisLine];
    if (!nextLine)
      break;
    
    self.scrollPosition = nextLine.range.location;
    self.scrollDelta -= DUX_LINE_HEIGHT;
  }
  if (self.scrollPosition == 0 && self.scrollDelta < 0.1) {
    self.scrollDelta = 0;
  }
  
  // if scroll delta is less than zero, add new lines until it's > 0
  while (self.scrollDelta < -0.9) {
    DuxLine *nextLine = [self.storage lineBeforeLine:[self.storage lineStartingAtByteLocation:self.scrollPosition]];
    if (!nextLine)
      break;
    
    self.scrollPosition = nextLine.range.location;
    self.scrollDelta += DUX_LINE_HEIGHT;
  }
  
  // enforce min/max
  NSUInteger max = [self maxScrollPosition];
  if (self.scrollPosition > max) {
    self.scrollPosition = max;
  }
  if (self.scrollPosition == max && self.scrollDelta > 0.9) {
    self.scrollDelta = 0;
  }
  if (self.scrollPosition == 0 && self.scrollDelta < 0) {
    self.scrollDelta = 0;
  }

  [self updateLayer];
}

- (BOOL)isOpaque
{
  return YES;
}

- (void)scrollPageUp:(id)sender
{
  [self scrollBy:self.frame.size.height animated:YES];
}

- (void)scrollPageDown:(id)sender
{
  [self scrollBy:0 - self.frame.size.height animated:YES];
}

- (void)scrollToBeginningOfDocument:(id)sender
{
  self.scrollPosition = 0;
  self.scrollDelta = 0;
  [self updateLayer];
}

- (void)scrollToEndOfDocument:(id)sender
{
  self.scrollPosition = self.maxScrollPosition;
  self.scrollDelta = 0;
  [self updateLayer];
}


@end
