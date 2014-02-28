//
// 
//  Dux
//
//  Created by Abhi Beckert on 2013-5-12.
//
//

#import "DuxTexStorageTests.h"
#import "DuxTextStorage.h"
#import "DuxLine.h"

@implementation DuxTexStorageTests

- (void)testInit
{
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
//  STAssertEqualObjects(@"", storage.string, nil);
  STAssertEquals((NSUInteger)0, storage.length, nil);
}

//- (void)testReplaceCharacters
//{
//  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
//  storage.data = [@"hello world" dataUsingEncoding:NSUTF8StringEncoding];
//  STAssertTrue([@"hello world" isEqualToString:storage.string], nil);
//  STAssertEquals(@"hello world".length, storage.length, nil);
//  
//  storage.data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
//  STAssertTrue([@"foohello world" isEqualToString:storage.string], @"got: %@", storage.string);
//  STAssertEquals(@"foohello world".length, storage.length, nil);
//  
//  [storage replaceCharactersInRange:NSMakeRange(3, 2) withString:@"bar" dataUsingEncoding:NSUTF8StringEncoding];
//  STAssertTrue([@"foobarllo world" isEqualToString:storage.string], @"got: %@", storage.string);
//  STAssertEquals(@"foobarllo world".length, storage.length, nil);
//  
//  [storage replaceCharactersInRange:NSMakeRange(storage.length, 0) withString:@"test" dataUsingEncoding:NSUTF8StringEncoding];
//  STAssertTrue([@"foobarllo worldtest" isEqualToString:storage.string], @"got: %@", storage.string);
//  STAssertEquals(@"foobarllo worldtest".length, storage.length, nil);
//}

- (void)testLineStartingAtByteLocation
{
  // storage with single line
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
  storage.data = [@"hello world" dataUsingEncoding:NSUTF8StringEncoding];
  
  DuxLine *line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:3];
  STAssertEquals(@"hel".length, line.range.location, nil);
  STAssertEquals(@"lo world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length];
  STAssertNil(line, nil);
  
  // storage with multiple lines
  storage = [[DuxTextStorage alloc] init];
  storage.data = [@"hello world\nfoobar\n\ntest\n" dataUsingEncoding:NSUTF8StringEncoding];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:3];
  STAssertEquals(@"hel".length, line.range.location, nil);
  STAssertEquals(@"lo world\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length];
  STAssertEquals(@"hello world".length, line.range.location, nil);
  STAssertEquals(@"\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\n".length];
  STAssertEquals(@"hello world\n".length, line.range.location, nil);
  STAssertEquals(@"foobar\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfo".length];
  STAssertEquals(@"hello world\nfo".length, line.range.location, nil);
  STAssertEquals(@"obar\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfoobar\n".length];
  STAssertEquals((NSUInteger)@"hello world\nfoobar\n".length, line.range.location, nil);
  STAssertEquals(@"\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfoobar\n\ntest\n".length];
  STAssertNil(line, nil);
  
  // storage with windows newlines
  storage = [[DuxTextStorage alloc] init];
  storage.data = [@"\r\nhello world\r\nfoobar\r\n\r\ntest\r\n" dataUsingEncoding:NSUTF8StringEncoding];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"\r\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:1];
  STAssertEquals(@"\n".length, line.range.location, nil);
  STAssertEquals(@"\n".length, line.range.length, nil);
  
  storage = [[DuxTextStorage alloc] init];
  storage.data = [@"hello world\r\nfoobar\r\n\r\ntest\r\n" dataUsingEncoding:NSUTF8StringEncoding];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world\r\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hel".length];
  STAssertEquals(@"hel".length, line.range.location, nil);
  STAssertEquals(@"lo world\r\n".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length];
  STAssertEquals(@"hello world".length, line.range.location, nil);
  STAssertEquals(@"\r\n".length, line.range.length, nil);
}

- (void)testBeforeAndAfterLine
{
  // basic test
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
  storage.data = [@"foo\nbar" dataUsingEncoding:NSUTF8StringEncoding];
  
  DuxLine *line = [storage lineStartingAtByteLocation:0];
  STAssertNil([storage lineBeforeLine:line], nil);
  STAssertEquals([storage lineAfterLine:line].range, [storage lineStartingAtByteLocation:@"foo\n".length].range, nil);
  
  line = [storage lineStartingAtByteLocation:@"foo\n".length];
  STAssertEquals([storage lineBeforeLine:line].range, [storage lineStartingAtByteLocation:0].range, nil);
  STAssertNil([storage lineAfterLine:line], nil);
  
  // test empty lines
  storage = [[DuxTextStorage alloc] init];
  storage.data = [@"\nfoo\n\nbar\n" dataUsingEncoding:NSUTF8StringEncoding];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertNil([storage lineBeforeLine:line], nil);
  STAssertEquals([storage lineAfterLine:line].range, [storage lineStartingAtByteLocation:@"\n".length].range, nil);
  
  line = [storage lineStartingAtByteLocation:@"\nfoo".length];
  STAssertEquals([storage lineAfterLine:line].range, [storage lineStartingAtByteLocation:@"\nfoo\n".length].range, nil);
  
  line = [storage lineStartingAtByteLocation:@"\nfoo\n".length];
  STAssertEquals([storage lineAfterLine:line].range, [storage lineStartingAtByteLocation:@"\nfoo\n\n".length].range, nil);
  
  line = [storage lineStartingAtByteLocation:@"\nfoo\n\nbar".length];
  STAssertEquals([storage lineAfterLine:line], [storage lineStartingAtByteLocation:@"\nfoo\n\nbar\n".length], nil);
}

- (void)testLastLine
{
  // empty storage
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
  storage.data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
  
  DuxLine *line = [storage lastLine];
  STAssertNil(line, nil);
  
  // real line at the end
  storage = [[DuxTextStorage alloc] init];
  storage.data = [@"foo\nbar" dataUsingEncoding:NSUTF8StringEncoding];
  
  line = [storage lastLine];
  STAssertEquals(line.range, NSMakeRange(@"foo\n".length, @"bar".length), nil);
  
  // empty unix newline at the end
  storage = [[DuxTextStorage alloc] init];
  storage.data = [@"foo\nbar\n" dataUsingEncoding:NSUTF8StringEncoding];
  
  line = [storage lastLine];
  STAssertEquals(line.range, NSMakeRange(@"foo\n".length, @"bar\n".length), nil);
  
  // empty windows newline at the end
  storage = [[DuxTextStorage alloc] init];
  storage.data = [@"foo\nbar\r\n" dataUsingEncoding:NSUTF8StringEncoding];
  
  line = [storage lastLine];
  STAssertEquals(line.range, NSMakeRange(@"foo\n".length, @"bar\r\n".length), nil);
}

@end
