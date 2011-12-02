//
//  DuxPreferencesController.h
//  Dux
//
//  Created by Abhi Beckert on 2011-12-02.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Cocoa/Cocoa.h>

@interface DuxPreferences : NSObject

+ (void)registerDefaults;

+ (NSFont *)editorFont;
+ (void)setEditorFont:(NSFont *)newFont;

@end

extern NSString *DuxPreferencesEditorFontDidChangeNotification;
