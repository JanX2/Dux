//
//  DuxJavaScriptLanguage.h
//  Dux
//
//  Created by Abhi Beckert on 2011-11-25.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxLanguage.h"
#import "DuxJavaScriptBaseElement.h"
#import "DuxJavaScriptSingleQuotedStringElement.h"
#import "DuxJavaScriptDoubleQuotedStringElement.h"
#import "DuxJavaScriptNumberElement.h"
#import "DuxJavaScriptKeywordElement.h"
#import "DuxJavaScriptSingleLineCommentElement.h"
#import "DuxJavaScriptBlockCommentElement.h"
#import "DuxJavaScriptRegexElement.h"

@interface DuxJavaScriptLanguage : DuxLanguage

+ (NSIndexSet *)keywordIndexSet;
+ (NSRange)keywordIndexRange;
+ (id)keywordIndexString;

- (void)findKeywordsInString:(NSString *)string inRange:(NSRange)range;

@end
