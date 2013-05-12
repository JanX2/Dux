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
  STAssertEqualObjects(0, storage.length, nil);
  
  [storage replaceCharactersInRange:NSMakeRange(0, 0) withString:@"hello world"];
  STAssertEqualObjects(@"hello world", storage.string, nil);
  STAssertEqualObjects(@"hello world".length, storage.length, nil);
}

@end
