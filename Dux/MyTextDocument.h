//
//  MyTextDocument.h
//  Dux
//
//  Created by Abhi Beckert on 2011-08-23.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import <Cocoa/Cocoa.h>
#import "DuxTextView.h"
#import "DuxLanguageMenuItem.h"
#import "DuxFileContentsWatcher.h"
#import "DuxTextStorage.h"

@class DuxProjectWindowController;

@interface MyTextDocument : NSDocument <DuxFileContentsWatcherDelegate> {
  DuxTextStorage *textContentStorage;
}
@property (unsafe_unretained) IBOutlet NSWindow *editorWindow;

@property (nonatomic, strong) NSTextStorage *textStorage;
@property (nonatomic, strong) DuxTextView *textView;
@property (nonatomic, strong) NSScrollView *scrollView;
@property NSStringEncoding stringEncoding;
//@property (nonatomic, strong) DuxFileContentsWatcher *fileContentsWatcher;


// Newline style to be used when inserting new text.
// The mask returned will only ever contain one of
// the possible DuxNewlineOptions options.
@property (nonatomic) DuxNewlineOptions activeNewlineStyle;

- (BOOL)convertContentToEncoding:(NSStringEncoding)newEncoding;
- (BOOL)reinterprateContentWithEncoding:(NSStringEncoding)newEncoding;

- (void)documentWindowDidBecomeKey:(NSNotification *)notification;

- (void)updateSyntaxMenuStates;
- (void)updateNewlineStyleMenuStates;
- (void)updateLineEndingsInUseMenuItem;
- (void)updateEncodingMenuItems;

- (IBAction)setDuxLanguage:(id)sender;
- (IBAction)setActiveNewlineStyleFromMenuItem:(NSMenuItem *)sender;
- (IBAction)convertToNewlineStyleFromMenuItem:(NSMenuItem *)sender;
- (IBAction)setActiveEncoding:(NSMenuItem *)sender;

- (void)loadIntoProjectWindowController:(DuxProjectWindowController *)controller documentView:(NSView *)documentView takeFirstResponder:(BOOL)makeFirstResponder;

@end
