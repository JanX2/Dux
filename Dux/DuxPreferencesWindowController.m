//
//  DuxPreferencesWindowController.m
//  Dux
//
//  Created by Abhi Beckert on 2011-12-01.
//  
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#import "DuxPreferencesWindowController.h"
#import "DuxPreferences.h"

@implementation DuxPreferencesWindowController
@synthesize fontTextField;
@synthesize showLineNumbersButton;
@synthesize showPageGuideButton;
@synthesize pageGuidePositionTextField;
@synthesize showOtherInstancesOfSelectedSymbolButton;
@synthesize indentStylePopUpButton;
@synthesize tabWidthTextField;
@synthesize indentWidthTextField;
@synthesize tabKeyBehaviourPopUpButton;
@synthesize lineWrappingButton;
@synthesize lineWrappingSizeTextField;

+ (void)showPreferencesWindow
{
  static DuxPreferencesWindowController *prefsController = nil;
  
  if (!prefsController) {
    prefsController = [[DuxPreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindow"];
  }
  
  [prefsController showWindow:self];
}

- (id)initWithWindow:(NSWindow *)window
{
  self = [super initWithWindow:window];
  if (self) {
    // Initialization code here.
  }
  
  return self;
}

- (void)windowDidLoad
{
  [super windowDidLoad];
  
  [showLineNumbersButton setEnabled:NO];
  [showPageGuideButton setEnabled:NO];
  [pageGuidePositionTextField setEnabled:NO];
  [showOtherInstancesOfSelectedSymbolButton setEnabled:NO];
  
  [indentStylePopUpButton setEnabled:NO];
  [tabWidthTextField setEnabled:NO];
  [indentWidthTextField setEnabled:NO];
  [tabKeyBehaviourPopUpButton setEnabled:NO];
  
  [lineWrappingButton setEnabled:NO];
  [lineWrappingSizeTextField setEnabled:NO];
}

- (IBAction)selectEditorFont:(id)sender
{
  [[NSFontManager sharedFontManager] setSelectedFont:[DuxPreferences editorFont] isMultiple:NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (void)changeFont:(id)sender
{
  NSFont *oldFont = [DuxPreferences editorFont];
  NSFont *newFont = [sender convertFont:oldFont];
  
  [DuxPreferences setEditorFont:newFont];
}

@end
