//
//  DuxBundle.m
//  Dux
//
//  Created by Abhi Beckert on 2013-1-1.
//
//

#import "DuxBundle.h"
#import "MyAppDelegate.h"
#import "DuxTextView.h"

const NSString *DuxBundleTypeCoScript = @"CoScript";
const NSString *DuxBundleTypeScript = @"Script";
const NSString *DuxBundleTypeSnippet = @"Snippet";
const NSString *DuxBundleInputTypeNone = @"None";
const NSString *DuxBundleInputTypeAlert = @"Alert";
const NSString *DuxBundleInputTypeSelection = @"Selection";
const NSString *DuxBundleInputTypeDocumentContents = @"DocumentContents";
const NSString *DuxBundleOutputTypeNone = @"None";
const NSString *DuxBundleOutputTypeInsertText = @"InsertText";
const NSString *DuxBundleOutputTypeInsertSnippet = @"InsertSnippet";
const NSString *DuxBundleOutputTypeReplaceDocument = @"ReplaceDocument";
const NSString *DuxBundleOutputTypeAlert = @"Alert";

static NSArray *loadedBundles;

@interface DuxBundle ()

@property NSString *displayName;
@property NSURL *URL;
@property NSBundle *fileBundle;
@property NSUInteger lastLoadHash; // hash of bundle filenames and modification dates
@property NSMenuItem *menuItem;
@property NSString *inputType;
@property NSString *outputType;
@property NSString *type;
@property NSURL *scriptURL;
@property NSURL *snippetURL;
@property NSArray *tabTriggers;
@property NSString *inputPrompt;

+ (void)unloadAllBundles;

// load or unload this bundle. unlike init/dealloc, a bundle object might be loaded/unloaded
// multiple items during it's lifecycle (eg: if the user edits the bundle while dux is open)
- (void)load;
- (void)unload;

// returns YES if bundle has never been loaded or if it has changed on disk and needs to be loaded again (note: these operations are slow and should not be done often)
- (BOOL)needsLoading;
+ (NSUInteger)calculateLoadHashForURL:(NSURL *)URL;

@end

@implementation DuxBundle

+ (void)initialize
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loadedBundles = [NSArray array];
  });
}

+ (DuxBundle *)bundleForSender:(id)sender
{
  return ((NSMenuItem *)sender).representedObject;
}

+ (NSURL *)bundlesURL
{
  static NSURL *bundlesURL = nil;
  if (bundlesURL) {
    return bundlesURL;
  }
  
  NSURL *appSupportDir = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] URLByAppendingPathComponent:@"Dux" isDirectory:YES];
  if (![appSupportDir checkResourceIsReachableAndReturnError:NULL]) {
    [[NSFileManager defaultManager] createDirectoryAtURL:appSupportDir withIntermediateDirectories:YES attributes:nil error:NULL];
  }
  
  bundlesURL = [appSupportDir URLByAppendingPathComponent:@"Bundles" isDirectory:YES];
  if (![bundlesURL checkResourceIsReachableAndReturnError:NULL]) {
    [self createBundlesDir:bundlesURL];
  }
  
  return bundlesURL;
}

+ (void)createBundlesDir:(NSURL *)bundlesURL
{
  NSURL *defaultBundles = [[NSBundle mainBundle] URLForResource:@"Default-Bundles" withExtension:nil];
  [[NSFileManager defaultManager] copyItemAtURL:defaultBundles toURL:bundlesURL error:NULL];
}

+ (NSArray *)allBundles
{
  return [loadedBundles copy];
}

+ (NSArray *)tabTriggerBundlesSortedByTriggerLength
{
  NSMutableArray *result = [NSMutableArray array];
  
  for (DuxBundle *bundle in [[self class] allBundles]) {
    if (bundle.tabTriggers.count == 0)
      continue;
    
    for (NSString *trigger in bundle.tabTriggers) {
      NSUInteger insertIndex = [result indexOfObject:@{@"trigger": trigger} inSortedRange:NSMakeRange(0, result.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(NSURL *leftObj, NSURL *rightObj) {
        NSString *leftTrigger = [leftObj valueForKey:@"trigger"];
        NSUInteger leftLength = leftTrigger.length;
        
        NSString *rightTrigger = [rightObj valueForKey:@"trigger"];
        NSUInteger rightLength = rightTrigger.length;
        
        if (leftLength < rightLength) {
          return -1;
        } else if (leftLength > rightLength) {
          return 1;
        } else {
          return [leftTrigger compare:rightTrigger];
        }
      }];
      [result insertObject:@{@"trigger": trigger, @"bundle": bundle} atIndex:insertIndex];
    }
  }
  
  return [result copy];
}

+ (void)loadBundles
{
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  NSURL *bundlesDir = [[self class] bundlesURL];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
    // create a copy of loadedBundles, so we can iterate it on a background thread to find
    // already loaded bundles, removing each one from this array as we process them, and
    // finally unloading any bundle still in this array at the end.
    __block NSMutableArray *previouslyLoadedBundles;
    dispatch_sync(dispatch_get_main_queue(), ^{
      previouslyLoadedBundles = [loadedBundles mutableCopy];
    });
    
    NSDirectoryEnumerator *bundlesDirEnumerator = [fileManager enumeratorAtURL:[bundlesDir URLByResolvingSymlinksInPath] includingPropertiesForKeys:@[NSURLIsPackageKey] options:NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:NULL];
    for (NSURL *bundleURL in bundlesDirEnumerator) {
      if (![@[@"coscript", @"duxbundle"] containsObject:bundleURL.pathExtension])
        continue;
      
      DuxBundle *bundle = nil;
      for (DuxBundle *previouslyLoadedBundle in previouslyLoadedBundles) {
        if ([previouslyLoadedBundle.URL isEqual:bundleURL]) {
          bundle = previouslyLoadedBundle;
          [previouslyLoadedBundles removeObject:bundle];
          break;
        }
      }
      
      if (!bundle) {
        bundle = [[DuxBundle alloc] init];
        bundle.URL = bundleURL;
        
        dispatch_sync(dispatch_get_main_queue(), ^{
          loadedBundles = [loadedBundles arrayByAddingObject:bundle];
        });
      }
      
      dispatch_sync(dispatch_get_main_queue(), ^{
        if ([bundle needsLoading]) {
          [bundle load];
        }
      });
    }
    
    for (DuxBundle *bundle in previouslyLoadedBundles) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        [bundle unload];
        
        NSMutableArray *mutableBundles = [loadedBundles mutableCopy];
        [mutableBundles removeObject:bundle];
        loadedBundles = [mutableBundles copy];
      });
    }
  });
}

+ (void)unloadAllBundles
{
  
}

- (void)load
{
  // unload if already loaded
  if (self.lastLoadHash != 0)
    [self unload];
  
  // load display name
  self.displayName = [[self.URL lastPathComponent] stringByDeletingPathExtension];
  NSURL *bundlesURL = [[self class] bundlesURL];
  if (![self.URL.path.stringByDeletingLastPathComponent isEqualToString:bundlesURL.path]) {
    NSArray *relativePathComponents = [self.URL.path.stringByDeletingLastPathComponent substringFromIndex:[[self class] bundlesURL].path.length + 1].pathComponents;
    
    for (NSString *folderName in relativePathComponents) {
      self.displayName = [NSString stringWithFormat:@"%@ › %@", folderName, self.displayName];
    }
  }
  
  // load as coscript?
  if ([self.URL.pathExtension isEqualToString:@"coscript"]) {
    self.type = (NSString *)DuxBundleTypeCoScript;
    self.scriptURL = self.URL;
    self.snippetURL = nil;
    self.inputType = (NSString *)DuxBundleInputTypeNone;
    self.outputType = (NSString *)DuxBundleOutputTypeNone;
    self.inputPrompt = nil;
    
    self.menuItem = [[NSMenuItem alloc] init];
    self.menuItem.title = [[self.URL lastPathComponent] stringByDeletingPathExtension];
    self.menuItem.action = @selector(performDuxBundle:);
    self.menuItem.representedObject = self;

    self.tabTriggers = @[];
    
    [self insertBundleMenuItem]; // inserts the menu item into the correct (alphabetically sorted) location
    
    self.lastLoadHash = [[self class] calculateLoadHashForURL:self.URL];
    
    return;
  }
  
  // load as bundle
  NSDictionary *infoDictionary = [[NSBundle bundleWithURL:self.URL] infoDictionary];
  self.type = [infoDictionary valueForKey:@"Type"];
  
  if ([self.type isEqualToString:(NSString *)DuxBundleTypeScript]) {
    self.scriptURL = [self.URL URLByAppendingPathComponent:[NSString stringWithFormat:@"Contents/%@", [infoDictionary valueForKey:@"Script"]]];
    self.snippetURL = nil;
  } else if ([self.type isEqualToString:(NSString *)DuxBundleTypeSnippet]) {
    self.snippetURL = [self.URL URLByAppendingPathComponent:[NSString stringWithFormat:@"Contents/%@", [infoDictionary valueForKey:@"Snippet"]]];
  } else {
    self.scriptURL = nil;
    self.snippetURL = nil;
  }
  
  self.inputType = [infoDictionary valueForKey:@"Input"];
  self.outputType = [infoDictionary valueForKey:@"Output"];
  
  self.inputPrompt = [infoDictionary valueForKey:@"InputPrompt"];
  
  self.menuItem = [[NSMenuItem alloc] init];
  self.menuItem.title = [[self.URL lastPathComponent] stringByDeletingPathExtension];
  self.menuItem.action = @selector(performDuxBundle:);
  self.menuItem.representedObject = self;
  
  NSMutableArray *tabTriggers = [NSMutableArray array];
  for (NSDictionary *trigger in [infoDictionary valueForKey:@"Triggers"]) {
    if ([[trigger valueForKey:@"Type"] isEqualToString:@"Key"]) {
      self.menuItem.keyEquivalentModifierMask = 0;
      for (NSString *keyComponent in [[trigger valueForKey:@"Key"] componentsSeparatedByString:@"+"]) {
        if ([keyComponent isEqualToString:@"Control"]) {
          self.menuItem.keyEquivalentModifierMask = self.menuItem.keyEquivalentModifierMask | NSControlKeyMask;
        } else if ([keyComponent isEqualToString:@"Option"]) {
          self.menuItem.keyEquivalentModifierMask = self.menuItem.keyEquivalentModifierMask | NSAlternateKeyMask;
        } else if ([keyComponent isEqualToString:@"Command"]) {
          self.menuItem.keyEquivalentModifierMask = self.menuItem.keyEquivalentModifierMask | NSCommandKeyMask;
        } else if ([keyComponent isEqualToString:@"Up"]) {
          unichar key = NSUpArrowFunctionKey;
          self.menuItem.keyEquivalent = [NSString stringWithCharacters:&key length:1];
        } else if ([keyComponent isEqualToString:@"Down"]) {
          unichar key = NSDownArrowFunctionKey;
          self.menuItem.keyEquivalent = [NSString stringWithCharacters:&key length:1];
        } else if ([keyComponent isEqualToString:@"Left"]) {
          unichar key = NSLeftArrowFunctionKey;
          self.menuItem.keyEquivalent = [NSString stringWithCharacters:&key length:1];
        } else if ([keyComponent isEqualToString:@"Right"]) {
          unichar key = NSRightArrowFunctionKey;
          self.menuItem.keyEquivalent = [NSString stringWithCharacters:&key length:1];
        } else if ([keyComponent isEqualToString:@"Space"]) {
          self.menuItem.keyEquivalent = @" ";
        } else if ([keyComponent isEqualToString:@"Tab"]) {
          self.menuItem.keyEquivalent = @"\t";
        } else if ([keyComponent isEqualToString:@"Return"]) {
          self.menuItem.keyEquivalent = @"\n";
        } else {
          self.menuItem.keyEquivalent = keyComponent;
        }
      }
    } else if ([[trigger valueForKey:@"Type"] isEqualToString:@"Tab"]) {
      NSString *word = [trigger valueForKey:@"Word"];
      if (word) {
        [tabTriggers addObject:word];
        self.menuItem.title = [NSString stringWithFormat:@"%@ (%@⇥)", self.menuItem.title, word];
      }
    }
  }
  self.tabTriggers = [tabTriggers copy];
  
  [self insertBundleMenuItem]; // inserts the menu item into the correct (alphabetically sorted) location
  
  self.lastLoadHash = [[self class] calculateLoadHashForURL:self.URL];
}

- (void)unload
{
  [self.menuItem.menu removeItem:self.menuItem];
  self.menuItem = nil; // incase of circular reference
  
  self.lastLoadHash = 0;
}

+ (NSUInteger)calculateLoadHashForURL:(NSURL *)URL
{
  // init a hash of this load operation
  NSUInteger prime = 31;
  NSUInteger loadHash = 1;
  
  NSNumber *isDirectory = nil;
  [URL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
  if (!isDirectory.boolValue) {
    NSString *fileName;
    NSNumber *fileSize;
    NSDate *fileModified;
    [URL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
    [URL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
    [URL getResourceValue:&fileModified forKey:NSURLContentModificationDateKey error:NULL];
    
    // update hash
    loadHash = prime * loadHash + URL.hash;
    loadHash = prime * loadHash + fileName.hash;
    loadHash = prime * loadHash + fileSize.hash;
    loadHash = prime * loadHash + fileModified.hash;
    
    return loadHash;
  }
  
  // iterate through all files, loading each one
  NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:URL includingPropertiesForKeys:nil options:0 errorHandler:NULL];
  for (NSURL *childURL in dirEnumerator) {
    // get details
    NSString *fileName;
    NSNumber *fileSize;
    NSDate *fileModified;
    [childURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
    [childURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
    [childURL getResourceValue:&fileModified forKey:NSURLContentModificationDateKey error:NULL];
    
    // update hash
    loadHash = prime * loadHash + childURL.hash;
    loadHash = prime * loadHash + fileName.hash;
    loadHash = prime * loadHash + fileSize.hash;
    loadHash = prime * loadHash + fileModified.hash;
  }
  
  return loadHash;
}

- (BOOL)needsLoading
{
  if (self.lastLoadHash == 0)
    return YES;
  
  return (self.lastLoadHash != [[self class] calculateLoadHashForURL:self.URL]);
}

- (void)insertBundleMenuItem
{
  NSMenu *menu = [(MyAppDelegate *)[NSApplication sharedApplication].delegate bundlesMenu];
  
  // figure out the submenu path
  NSURL *bundlesURL = [[self class] bundlesURL];
  if (![self.URL.path.stringByDeletingLastPathComponent isEqualToString:bundlesURL.path]) {
    NSArray *relativePathComponents = [self.URL.path.stringByDeletingLastPathComponent substringFromIndex:[[self class] bundlesURL].path.length + 1].pathComponents;
    
    for (NSString *submenuTitle in relativePathComponents) {
      NSMenuItem *submenuItem = [menu itemWithTitle:submenuTitle];
      if (!submenuItem) {
        submenuItem = [[NSMenuItem alloc] init];
        submenuItem.title = submenuTitle;
        submenuItem.submenu = [[NSMenu alloc] init];
        
        NSUInteger index = 0;
        for (NSMenuItem *existingMenuItem in menu.itemArray) {
          if (existingMenuItem.isSeparatorItem)
            break;
          if ([existingMenuItem.title compare:submenuTitle options:NSNumericSearch] == NSOrderedDescending)
            break;
          
          index++;
        }
        [menu insertItem:submenuItem atIndex:index];
      }
      
      menu = submenuItem.submenu;
    }
  }
  
  // find either the separator item, or the first item who's title is NSOrderedDescending compared to ours, and insert it there
  NSUInteger index = 0;
  for (NSMenuItem *existingMenuItem in menu.itemArray) {
    if (existingMenuItem.isSeparatorItem)
      break;
    
    if ([existingMenuItem.title compare:self.menuItem.title options:NSNumericSearch] == NSOrderedDescending) {
      break;
    }
    
    index++;
  }
  
  [menu insertItem:self.menuItem atIndex:index];
}

- (NSString *)runWithWorkingDirectory:(NSURL *)workingDirectoryURL currentFile:(NSURL *)currentFile editorView:(DuxTextView *)editorView
{
  NSString *input = nil;
  if ([self.inputType isEqual:DuxBundleInputTypeAlert]) {
    NSAlert *alert = [NSAlert alertWithMessageText:self.displayName defaultButton:@"Continue" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"%@", self.inputPrompt ? self.inputPrompt : @""];
    
    NSTextField *accessory = [[NSTextField alloc] initWithFrame:NSMakeRect(0,0,290,22)];
    [alert setAccessoryView:accessory];
    
    NSUInteger buttonPressed = [alert runModal];
    if (buttonPressed != NSAlertDefaultReturn)
      return nil;
    
    input = accessory.stringValue;
  } else if ([self.inputType isEqual:DuxBundleInputTypeDocumentContents]) {
    input = editorView.textStorage.string;
  } else if ([self.inputType isEqual:DuxBundleInputTypeSelection]) {
    input = editorView.textStorage.string;
    if (editorView.selectedRange.length > 0)
      input = [input substringWithRange:editorView.selectedRange];
  }

  NSString *output;
  if ([self.type isEqualToString:(NSString *)DuxBundleTypeCoScript]) { // Cocoa Script
    COScript *coScript = [[COScript alloc] init];
    coScript.errorController = self;
    
    @try {
      [coScript executeString:[NSString stringWithContentsOfURL:self.scriptURL usedEncoding:nil error:NULL]];
      [coScript callFunctionNamed:@"run" withArguments:@[editorView]];
    }
    @catch (NSException *exception) {
      NSAlert *alert = [NSAlert alertWithMessageText:@"Exception Running Script" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@\n%@\n%@", exception.name, exception.reason, exception.userInfo];
      [alert runModal];
    }
  } else if ([self.type isEqualToString:(NSString *)DuxBundleTypeScript]) { // UNIX script
    NSTask *task = [[NSTask alloc] init];
    if (input)
      task.arguments = @[input];
    task.launchPath = self.scriptURL.path;
    task.standardOutput = [NSPipe pipe];
    task.currentDirectoryPath = workingDirectoryURL.path;
    
    
    NSMutableDictionary *env = [NSProcessInfo processInfo].environment.mutableCopy;
    [env setObject:currentFile ? currentFile.path : @"" forKey:@"DuxCurrentFile"];
    task.environment = env.copy;
    
    [task launch];
    [task waitUntilExit];
    
    NSData *standardOutput = [[(NSPipe *)task.standardOutput fileHandleForReading] readDataToEndOfFile];
    output = [[NSString alloc] initWithData:standardOutput encoding:NSUTF8StringEncoding];
  } else if ([self.type isEqualToString:(NSString *)DuxBundleTypeSnippet]) {
    output = [NSString stringWithContentsOfURL:self.snippetURL usedEncoding:NULL error:NULL];
  } else {
    return @"";
  }
  
  
  if (output.length > 0 && [self.outputType isEqualToString:(NSString *)DuxBundleOutputTypeAlert]) {
    NSAlert *alert = [NSAlert alertWithMessageText:self.displayName defaultButton:@"Dismiss" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", output];
    [alert runModal];
    return nil;
  }
  
  return output;
}

// TODO: this never seems to get called. Bug in coscript?
- (void)coscript:(id)coscript hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url;
{
  NSAlert *alert = [NSAlert alertWithMessageText:@"Script Error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Line: %lu\nError: %@", lineNumber, error];
  [alert runModal];
}

@end
