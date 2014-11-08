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
  XCTAssertNil(nextElement, @"nextElement should be nil");
  XCTAssertEqual(length, (NSUInteger)8);
  
  
  nextElement = nil;
  length = [[DuxPHPDoubleQuoteStringElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo \"string$\" bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement, @"should be nil but is %@", nextElement);
  XCTAssertEqual(length, (NSUInteger)9);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxPHPNumberElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)4);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxPHPNumberElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)4);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)2);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)2);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42;"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)2);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42 bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)9);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42"] startingAt:0 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)5);
  
  nextElement = nil;
  length = [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)9);
  
  nextElement = nil;
  length = [[DuxPHPNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 0xFF bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)4);
  
  nextElement = nil;
  [[DuxPHPBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo true bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxPHPKeywordElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)4);
}

- (void)testJavaScript
{
  id nextElement = nil;
  NSUInteger length = [[DuxJavaScriptRegexElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo /regex/ bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)7);
  
  nextElement = nil;
  length = [[DuxJavaScriptRegexElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo /re\\/gex/ bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)9);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxJavaScriptNumberElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)4);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxJavaScriptNumberElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)4);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42 bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)2);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)2);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42;"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)2);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42 bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)9);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo42"] startingAt:0 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)5);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 42bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)9);
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo true bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxJavaScriptKeywordElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)4);
  
  
  nextElement = nil;
  length = [[DuxJavaScriptBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo (42) bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxJavaScriptNumberElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)5);
  
  nextElement = nil;
  length = [[DuxJavaScriptNumberElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo 0xFF bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)4);
}

- (void)testCss
{
  XCTAssertFalse([DuxCSSLanguage isDefaultLanguageForURL:[NSURL fileURLWithPath:@"~/foo.bar"] textContents:nil]);
  XCTAssertTrue([DuxCSSLanguage isDefaultLanguageForURL:[NSURL fileURLWithPath:@"~/foo.css"] textContents:nil]);
  XCTAssertTrue([DuxCSSLanguage isDefaultLanguageForURL:[NSURL fileURLWithPath:@"~/foo.less"] textContents:nil]);
  
  id nextElement = nil;
  NSUInteger length = [[DuxCSSBaseElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo @rule bar"] startingAt:0 nextElement:&nextElement];
  XCTAssertEqual(nextElement, [DuxCSSAtRuleElement sharedInstance]);
  XCTAssertEqual(length, (NSUInteger)4);
  
  nextElement = nil;
  length = [[DuxCSSAtRuleElement sharedInstance] lengthInString:[[NSAttributedString alloc] initWithString:@"foo @rule bar"] startingAt:4 nextElement:&nextElement];
  XCTAssertNil(nextElement);
  XCTAssertEqual(length, (NSUInteger)5);
}

@end
