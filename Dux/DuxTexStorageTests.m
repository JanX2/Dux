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
  STAssertEqualObjects(@"", storage.string, nil);
  STAssertEquals((NSUInteger)0, storage.length, nil);
}

- (void)testReplaceCharacters
{
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"hello world"];
  STAssertTrue([@"hello world" isEqualToString:storage.string], nil);
  STAssertEquals(@"hello world".length, storage.length, nil);
  
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"foo"];
  STAssertTrue([@"foohello world" isEqualToString:storage.string], @"got: %@", storage.string);
  STAssertEquals(@"foohello world".length, storage.length, nil);
  
  [storage replaceCharactersInRange:NSMakeRange(3, 2) withString:@"bar"];
  STAssertTrue([@"foobarllo world" isEqualToString:storage.string], @"got: %@", storage.string);
  STAssertEquals(@"foobarllo world".length, storage.length, nil);
  
  [storage replaceCharactersInRange:NSMakeRange(storage.length, 0) withString:@"test"];
  STAssertTrue([@"foobarllo worldtest" isEqualToString:storage.string], @"got: %@", storage.string);
  STAssertEquals(@"foobarllo worldtest".length, storage.length, nil);
}

- (void)testLineAtCharacterPosition
{
  // storage with single line
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"hello world"];
  
  DuxLine *line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:3];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  // storage with multiple lines
  storage = [[DuxTextStorage alloc] init];
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"hello world\nfoobar\n\ntest\n"];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:3];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length + 1];
  STAssertEquals((NSUInteger)@"hello world".length + 1, line.range.location, nil);
  STAssertEquals(@"foobar".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length + 3];
  STAssertEquals((NSUInteger)@"hello world".length + 1, line.range.location, nil);
  STAssertEquals(@"foobar".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfoobar".length];
  STAssertEquals((NSUInteger)@"hello world".length + 1, line.range.location, nil);
  STAssertEquals(@"foobar".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfoobar\n".length];
  STAssertEquals((NSUInteger)@"hello world\nfoobar".length + 1, line.range.location, nil);
  STAssertEquals(@"".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfoobar\n\n".length];
  STAssertEquals((NSUInteger)@"hello world\nfoobar\n".length + 1, line.range.location, nil);
  STAssertEquals(@"test".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfoobar\n\ntest".length];
  STAssertEquals((NSUInteger)@"hello world\nfoobar\n".length + 1, line.range.location, nil);
  STAssertEquals(@"test".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\nfoobar\n\ntest\n".length];
  STAssertEquals((NSUInteger)@"hello world\nfoobar\n\ntest\n".length, line.range.location, nil);
  STAssertEquals(@"".length, line.range.length, nil);
  
  // storage with windows newlines
  storage = [[DuxTextStorage alloc] init];
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"\r\nhello world\r\nfoobar\r\n\r\ntest\r\n"];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:1];
  STAssertEquals(@"\r\n".length, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  storage = [[DuxTextStorage alloc] init];
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"hello world\r\nfoobar\r\n\r\ntest\r\n"];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:3]; 
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length];
  STAssertEquals((NSUInteger)0, line.range.location, nil);
  STAssertEquals(@"hello world".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length + 1];
  STAssertEquals((NSUInteger)@"hello world\r\n".length, line.range.location, nil);
  STAssertEquals(@"foobar".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length + 2];
  STAssertEquals((NSUInteger)@"hello world\r\n".length, line.range.location, nil);
  STAssertEquals(@"foobar".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world".length + 3];
  STAssertEquals((NSUInteger)@"hello world\r\n".length, line.range.location, nil);
  STAssertEquals(@"foobar".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\r\nfoobar".length];
  STAssertEquals((NSUInteger)@"hello world\r\n".length, line.range.location, nil);
  STAssertEquals(@"foobar".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\r\nfoobar\r\n".length];
  STAssertEquals((NSUInteger)@"hello world\r\nfoobar\r\n".length, line.range.location, nil);
  STAssertEquals(@"".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\r\nfoobar\r\n\r\n".length];
  STAssertEquals((NSUInteger)@"hello world\r\nfoobar\r\n\r\n".length, line.range.location, nil);
  STAssertEquals(@"test".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\r\nfoobar\r\n\r\ntest".length];
  STAssertEquals((NSUInteger)@"hello world\r\nfoobar\r\n\r\n".length, line.range.location, nil);
  STAssertEquals(@"test".length, line.range.length, nil);
  
  line = [storage lineStartingAtByteLocation:@"hello world\r\nfoobar\r\n\r\ntest\r\n".length];
  STAssertEquals((NSUInteger)@"hello world\r\nfoobar\r\n\r\ntest\r\n".length, line.range.location, nil);
  STAssertEquals(@"".length, line.range.length, nil);
}

- (void)testBeforeAndAfterLine
{
  // basic test
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"foo\nbar"];
  
  DuxLine *line = [storage lineStartingAtByteLocation:0];
  STAssertNil([storage lineBeforeLine:line], nil);
  STAssertEquals([storage lineAfterLine:line], [storage lineAtCharacterPosition:@"foo\n".length], nil);
  
  line = [storage lineStartingAtByteLocation:@"foo\n".length];
  STAssertEquals([storage lineBeforeLine:line], [storage lineAtCharacterPosition:0], nil);
  STAssertNil([storage lineAfterLine:line], nil);
  
  // test empty lines
  storage = [[DuxTextStorage alloc] init];
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"\nfoo\n\nbar\n"];
  
  line = [storage lineStartingAtByteLocation:0];
  STAssertNil([storage lineBeforeLine:line], nil);
  STAssertEquals([storage lineAfterLine:line], [storage lineAtCharacterPosition:@"\n".length], nil);
  
  line = [storage lineStartingAtByteLocation:@"\nfoo".length];
  STAssertEquals([storage lineAfterLine:line], [storage lineAtCharacterPosition:@"\nfoo\n".length], nil);
  
  line = [storage lineStartingAtByteLocation:@"\nfoo\n".length];
  STAssertEquals([storage lineAfterLine:line], [storage lineAtCharacterPosition:@"\nfoo\n\n".length], nil);
  
  line = [storage lineStartingAtByteLocation:@"\nfoo\n\nbar".length];
  STAssertEquals([storage lineAfterLine:line], [storage lineAtCharacterPosition:@"\nfoo\n\nbar\n".length], nil);
  
  
}

@end
