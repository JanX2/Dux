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
  NSUInteger length = [[DuxPHPDoubleQuoteStringElement sharedInstance] lengthInString:@"foo \"string\" bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, @"nextElement should be nil");
  STAssertEquals(length, (NSUInteger)8, nil);
  
  
  nextElement = nil;
  length = [[DuxPHPDoubleQuoteStringElement sharedInstance] lengthInString:@"foo \"string$\" bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, @"should be nil but is %@", nextElement);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:@"foo 42 bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxPHPNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:@"foo 42" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxPHPNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:@"foo 42 bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:@"foo 42" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:@"foo 42;" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:@"foo42 bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:@"foo42" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)5, nil);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:@"foo 42bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:@"foo 0xFF bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  [[DuxPHPBaseElement sharedInstance] lengthInString:@"foo true bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxPHPKeywordElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
}

- (void)testJavaScript
{
  id nextElement = nil;
  NSUInteger length = [[DuxJavaScriptRegexElement sharedInstance] lengthInString:@"foo /regex/ bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)7, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptRegexElement sharedInstance] lengthInString:@"foo /re\\/gex/ bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:@"foo 42 bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxJavaScriptNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:@"foo 42" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxJavaScriptNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:@"foo 42 bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:@"foo 42" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:@"foo 42;" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)2, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:@"foo42 bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:@"foo42" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)5, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:@"foo 42bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)9, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:@"foo true bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxJavaScriptKeywordElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:@"foo (42) bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxJavaScriptNumberElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)5, nil);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:@"foo 0xFF bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)4, nil);
}

- (void)testCss
{
  STAssertFalse([DuxCSSLanguage isDefaultLanguageForURL:[NSURL fileURLWithPath:@"~/foo.bar"] textContents:nil], nil);
  STAssertTrue([DuxCSSLanguage isDefaultLanguageForURL:[NSURL fileURLWithPath:@"~/foo.css"] textContents:nil], nil);
  STAssertTrue([DuxCSSLanguage isDefaultLanguageForURL:[NSURL fileURLWithPath:@"~/foo.less"] textContents:nil], nil);
  
  id nextElement = nil;
  NSUInteger length = [[DuxCSSBaseElement sharedInstance] lengthInString:@"foo @rule bar" startingAt:0 didJustPop:NO nextElement:&nextElement];
  STAssertEquals(nextElement, [DuxCSSAtRuleElement sharedInstance], nil);
  STAssertEquals(length, (NSUInteger)4, nil);
  
  nextElement = nil;
  length = [[DuxCSSAtRuleElement sharedInstance] lengthInString:@"foo @rule bar" startingAt:4 didJustPop:NO nextElement:&nextElement];
  STAssertNil(nextElement, nil);
  STAssertEquals(length, (NSUInteger)5, nil);
}

@end
