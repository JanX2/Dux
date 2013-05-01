//
//  DuxSyntaxHighlighterTests.m
//  DuxSyntaxHighlighterTests
//
//  Created by Abhi Beckert on 2013-4-26.
//
//

#import "DuxSyntaxHighlighterTests.h"
#import "DuxPHPLanguage.h"
#import "DuxJavaScriptLanguage.h"
#import "DuxCSSLanguage.h"

@implementation DuxSyntaxHighlighterTests

- (void)setUp
{
  [super setUp];
}

- (void)tearDown
{
  [super tearDown];
}

- (void)testPHP
{
  id nextElement = nil;
  NSUInteger length = [[DuxPHPDoubleQuoteStringElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo \"string\" bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, @"nextElement should be nil");
  STAssertEquals(length, (NSUInteger)8, nil);
  
  
  nextElement = nil;
  length = [[DuxPHPDoubleQuoteStringElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo \"string$\" bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, @"should be nil but is %@", nextElement);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:0 nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxPHPNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:0 nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxPHPNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42;"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42 bar"] startingAt:0 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42"] startingAt:0 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)5, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42bar"] startingAt:0 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 0xFF bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)4, nil);
}

- (void)testJavaScript
{
  id nextElement = nil;
  NSUInteger length = [[DuxJavaScriptRegexElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo /regex/ bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)7, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptRegexElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo /re\\/gex/ bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:0 nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxJavaScriptNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:0 nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxJavaScriptNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42;"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42 bar"] startingAt:0 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42"] startingAt:0 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)5, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42bar"] startingAt:0 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo (42) bar"] startingAt:0 nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxJavaScriptNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)5, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 0xFF bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)4, nil);
}

- (void)testCss
{
  id nextElement = nil;
  NSUInteger length = [[DuxCSSBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo @rule bar"] startingAt:0 nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxCSSAtRuleElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxCSSAtRuleElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo @rule bar"] startingAt:4 nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)5, nil);
}

@end
