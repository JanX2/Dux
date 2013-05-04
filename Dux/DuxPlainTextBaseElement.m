//
//  DuxPlainTextBaseElement.m
//  Dux
//
//  Created by Abhi Beckert on 2011-11-20.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPlainTextBaseElement.h"
#import "DuxPlainTextLanguage.h"

@implementation DuxPlainTextBaseElement

- (id)init
{
  return [self initWithLanguage:[DuxPlainTextLanguage sharedInstance]];
}

- (NSUInteger)lengthInString:(NSString *)string startingAt:(NSUInteger)startingAt didJustPop:(BOOL)didJustPop nextElement:(DuxLanguageElement *__strong*)nextElement
{
  return string.length - startingAt;
}

@end
