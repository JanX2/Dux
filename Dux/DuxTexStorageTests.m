//
//  DuxTexStorageTests.m
//  Dux
//
//  Created by Abhi Beckert on 2013-5-12.
//
//

#import "DuxTexStorageTests.h"
#import "DuxTextStorage.h"

@implementation DuxTexStorageTests

- (void)testInit
{
  DuxTextStorage *storage = [[DuxTextStorage alloc] init];
  STAssertEqualObjects(@"", storage.string, nil);
  STAssertEquals((NSUInteger)0, storage.length, nil);
  
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"hello world"];
  STAssertTrue([@"hello world" isEqualToString:storage.string], nil);
  STAssertEquals(@"hello world".length, storage.length, nil);
}

@end
