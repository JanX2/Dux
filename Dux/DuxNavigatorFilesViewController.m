//
//  DuxNavigatorFilesViewController.m
//  Dux
//
//  Created by Abhi Beckert on 2013-4-20.
//
//  This is free and unencumbered software released into the public domain.
//  For more information, please refer to <http://unlicense.org/>
//

#include <CoreServices/CoreServices.h>

#import "DuxNavigatorFilesViewController.h"
#import "DuxNavigatorFileCell.h"
#import "DuxTheme.h"
#import "DuxPreferences.h"

NSString * const kFileColumnName = @"FileColumn"; // Name for the file column
#define kIconImageSize  16.0
#define kRefreshDelay 0.6

static NSArray *filesExcludeList;
static NSString *DuxFSEventNotification = @"DuxFSEventNotification";

void fs_event_cb(ConstFSEventStreamRef stream,
                 void *userData,
                 size_t numEvents,
                 void *eventPaths,
                 const FSEventStreamEventFlags eventFlags[],
                 const FSEventStreamEventId eventIds[]);

@interface DuxNavigatorFilesViewController ()
{
  NSImage						*folderImage;
  FSEventStreamRef fsStream;
}

@property NSTableColumn *fileTableColumn;

@property NSMutableSet *cachedUrls;
@property NSMutableSet *cacheQueuedUrls;
@property NSMutableDictionary *urlIsDirectoryCache;
@property NSMutableDictionary *urlChildUrlsCache;

@property NSOperationQueue *cacheQueue;

@end

@implementation DuxNavigatorFilesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    return nil;

  [self initialize];

  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  if (!(self = [super initWithCoder:aDecoder]))
    return nil;

  [self initialize];

  return self;
}

- (void)initialize
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileSystemDidChange:) name:DuxFSEventNotification object:nil];
  [self flushCache];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self stopFileSystemWatcher];
}

- (void)flushCache
{
  self.urlIsDirectoryCache = @{}.mutableCopy;
  self.urlChildUrlsCache = @{}.mutableCopy;
  self.urlIsDirectoryCache = @{}.mutableCopy;
  self.cachedUrls = [[NSMutableSet alloc] init];
  self.cacheQueuedUrls = [[NSMutableSet alloc] init];
  
  self.cacheQueue = [[NSOperationQueue alloc] init];
  self.cacheQueue.maxConcurrentOperationCount = 1;
  
  if (!filesExcludeList) {
    filesExcludeList = @[@".svn",@".git"];
  }
}

- (void)awakeFromNib
{
  [self initOutlineCells];
  self.filesView.enclosingScrollView.scrollerKnobStyle = [[DuxTheme currentTheme] scrollerKnobStyle];
}

- (void)initOutlineCells
{
  NSTableColumn *tableColumn = [self.filesView tableColumnWithIdentifier:kFileColumnName];
  self.fileTableColumn = tableColumn;

  DuxNavigatorFileCell *imageAndTextCell = [[DuxNavigatorFileCell alloc] init];
  [imageAndTextCell setEditable:YES];
  [tableColumn setDataCell:imageAndTextCell];
  
  folderImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
  [folderImage setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  // root?
  if (!item)
    item = self.rootURL;
  
  // nil item? root is sometimes nil
  if (!self.rootURL)
    return 0;
  
  // is it in the cache yet? if not add it to the chache
  if (![self.cachedUrls containsObject:item]) {
    BOOL didFillQuickly = [self cacheDidMiss:item waitUntilFinished:20];
    if (!didFillQuickly)
      return 1;
  }
  
  return [[self.urlChildUrlsCache objectForKey:item] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  // string? eg loading status
  if ([item isKindOfClass:[NSString class]])
    return NO;
  
  // assume it's a url
  NSURL *url = item;
  
  // check value
  NSNumber *isPackage = @NO;
  NSNumber *isDirectory = @NO;
  [url getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
  [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
  
  return (isDirectory.boolValue && !isPackage.boolValue);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  // root?
  if (!item)
    item = self.rootURL;
  
  // is it in the cache yet? if not add it
  if (![self.cachedUrls containsObject:item]) {
    [self cacheDidMiss:item waitUntilFinished:0];
    return @"❔";
  }
  
  return [[self.urlChildUrlsCache objectForKey:item] objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  // Not a URL? Maybe a string? eg loading status -> return directly.
  if (![item isKindOfClass:[NSURL class]])
    return item;
  
  // it's a url
  NSURL *url = item;
  
  // return it
  return url.lastPathComponent;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  DuxNavigatorFileCell *cell = [tableColumn dataCell];
	return cell;
}

- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if (tableColumn != _fileTableColumn) {
    return;
  }
  
  NSTextFieldCell *textCell = [tableColumn dataCell];
  textCell.textColor = [[DuxTheme currentTheme] foreground];
  
  if ([self outlineView:olv isItemExpandable:item])
  {
    ((DuxNavigatorFileCell *)cell).image = folderImage;
  }
  else {
    NSString *fileExtension = [(NSURL *)item pathExtension];
    ((DuxNavigatorFileCell *)cell).image = [[NSWorkspace sharedWorkspace] iconForFileType:fileExtension];
  }
}

- (void)setRootURL:(NSURL *)rootURL
{
  if ([rootURL isEqual:_rootURL])
    return;

  [self stopFileSystemWatcher];

  CFStringRef path = (__bridge CFStringRef)(rootURL.path);
  CFArrayRef pathsToWatch = CFArrayCreate(kCFAllocatorDefault, (const void **)&path, 1, NULL);
  fsStream = FSEventStreamCreate(kCFAllocatorDefault,
                                 fs_event_cb,
                                 NULL,
                                 pathsToWatch,
                                 kFSEventStreamEventIdSinceNow,
                                 kRefreshDelay,
                                 kFSEventStreamCreateFlagWatchRoot);
  FSEventStreamScheduleWithRunLoop(fsStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(fsStream);
  CFRelease(pathsToWatch);

  [self.cacheQueue setSuspended:YES];
  [self.cacheQueue cancelAllOperations];
  
  _rootURL = rootURL;
  
  self.urlIsDirectoryCache = @{}.mutableCopy;
  self.urlChildUrlsCache = @{}.mutableCopy;
  self.urlIsDirectoryCache = @{}.mutableCopy;
  self.cachedUrls = [[NSMutableSet alloc] init];
  
  [self.cacheQueue setSuspended:NO];
  
  [self.filesView reloadData];
}

- (BOOL)cacheDidMiss:(NSURL *)url waitUntilFinished:(NSUInteger)millisecondsToWait
{
  if ([self.cacheQueuedUrls containsObject:url])
    return NO;
  
  [self.cacheQueuedUrls addObject:url];
  
  __block BOOL isDone = NO;
  __block NSMutableArray *mutableChildUrls = nil;
  __block NSArray *childUrls;
  
  
  [self.cacheQueue addOperationWithBlock:^{
    // make sure it isn't already cached (we often have a cache miss on the same URL many times)
    // get children, and sort them
    childUrls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url includingPropertiesForKeys:@[NSURLIsPackageKey, NSURLIsDirectoryKey] options:0 error:NULL];
    
    mutableChildUrls = [[NSMutableArray alloc] initWithArray:childUrls];
    
    NSIndexSet *matchingPathsSet = [mutableChildUrls indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
      NSString *fileComponent = [(NSURL *)obj lastPathComponent];
      if ([filesExcludeList containsObject:fileComponent] ) {
        return true;
      }
      return false;
    }];
    
    [mutableChildUrls removeObjectsInArray:[childUrls objectsAtIndexes:matchingPathsSet]];
    
    childUrls = [self sortedFiles:mutableChildUrls];

    isDone = YES;
    
    // add to cache and update display
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([self.cachedUrls containsObject:url])
        return;
      
      [self.cachedUrls addObject:url];
      [self.cacheQueuedUrls removeObject:url];
      [self.urlIsDirectoryCache setObject:[NSNumber numberWithBool:NO] forKey:url];
      [self.urlChildUrlsCache setObject:childUrls forKey:url];
      [self.urlIsDirectoryCache setObject:[NSNumber numberWithBool:NO] forKey:url];
      
      [self.filesView reloadData];
    });
  }];
  
  // wait for some milliseconds for the cache to data to be fetched. check every 0.002 seconds if it's in the cache yet
  if (millisecondsToWait != 0) {
    NSDate *startWait = [NSDate date];
    NSTimeInterval seconds = millisecondsToWait;
    seconds = (0 - seconds / 1000);
    
    while (!isDone && [startWait timeIntervalSinceNow] > seconds) {
      usleep(0.002 * 100);
    }
    
    if (isDone) {
      [self.cachedUrls addObject:url];
      [self.cacheQueuedUrls removeObject:url];
      [self.urlIsDirectoryCache setObject:[NSNumber numberWithBool:NO] forKey:url];
      [self.urlChildUrlsCache setObject:childUrls forKey:url];
      [self.urlIsDirectoryCache setObject:[NSNumber numberWithBool:NO] forKey:url];
      
      return YES;
    }
  }
  
  return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
  NSIndexSet *selectedRows = [self.filesView selectedRowIndexes];
  
  // if we only selected one item, open it
  if (selectedRows.count == 1) {
    NSURL *selectedUrl = [self.filesView itemAtRow:selectedRows.firstIndex];
    
    NSNumber *isPackage = @NO;
    NSNumber *isDirectory = @NO;
    [selectedUrl getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
    [selectedUrl getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    
    if (!isDirectory.boolValue && !isPackage.boolValue) {
      if (self.delegate && [self.delegate respondsToSelector:@selector(duxNavigatorDidSelectFile:)]) {
        [self.delegate duxNavigatorDidSelectFile:selectedUrl];
      }
    }
  }
}

- (IBAction)editSelectedRow
{
  [self.filesView editColumn:0 row:[self.filesView selectedRow] withEvent:[NSApp currentEvent] select:YES];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
  NSLog(@"edit %@", tableColumn);
  [self.filesView editColumn:0 row:[self.filesView selectedRow] withEvent:[NSApp currentEvent] select:YES];
  return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn
{
  NSIndexSet *selectedRows = [self.filesView selectedRowIndexes];
  NSLog(@"Got a click at %ld",(unsigned long)selectedRows.firstIndex);
}

- (IBAction)revealFileInFinder:(id)sender
{
  NSURL *urlForClickedRow;
  
  NSInteger clickedRow = [self.filesView clickedRow];
  if (clickedRow == -1) {
    urlForClickedRow = self.rootURL;
  } else {
    urlForClickedRow = [self.filesView itemAtRow:clickedRow];
  }

  [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[urlForClickedRow]];
}

- (IBAction)newFile:(id)sender
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  // find the target row
  NSURL *parentDir;
  NSInteger clickedRow = [self.filesView clickedRow];
  if (clickedRow == -1) {
    parentDir = self.rootURL;
  } else {
    NSURL *urlForClickedRow = [self.filesView itemAtRow:clickedRow];
    
    
    // figure out the parent dir (if selected row is a directory, make it a child. otherwise a sibling)
    BOOL clickedRowIsDir;
    BOOL clickedRowExists = [fileManager fileExistsAtPath:urlForClickedRow.path isDirectory:&clickedRowIsDir];
    if (!clickedRowExists) {
      NSBeep();
      return;
    }
    parentDir = clickedRowIsDir ? urlForClickedRow : urlForClickedRow.URLByDeletingLastPathComponent;
  }
  
  // show save panel
  NSSavePanel *savePanel = [NSSavePanel savePanel];
  savePanel.showsHiddenFiles = YES;
  savePanel.directoryURL = parentDir;
  [savePanel beginSheetModalForWindow:self.filesView.window completionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelCancelButton)
      return;
    
    // create the file
    [fileManager createFileAtPath:savePanel.URL.path contents:[NSData data] attributes:nil];
    
    // reload file navigator, and select the new file
    [self flushCache];
    [self.filesView reloadData];
    [self revealFileInNavigator:savePanel.URL];

    // open the new file
    if ([self.delegate respondsToSelector:@selector(duxNavigatorDidCreateFile:)]) {
      [self.delegate duxNavigatorDidCreateFile:savePanel.URL];
    }
    
  }];
}

- (IBAction)moveFile:(id)sender
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  // find the target row
  NSInteger clickedRow = [self.filesView clickedRow];
  if (clickedRow == -1) {
    NSBeep();
    return;
  }
  NSURL *urlForClickedRow = [self.filesView itemAtRow:clickedRow];
  
  // show save panel
  NSSavePanel *savePanel = [NSSavePanel savePanel];
  savePanel.showsHiddenFiles = YES;
  savePanel.directoryURL = urlForClickedRow.URLByDeletingLastPathComponent;
  savePanel.nameFieldStringValue = urlForClickedRow.lastPathComponent;
  [savePanel beginSheetModalForWindow:self.filesView.window completionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelCancelButton)
      return;
    
    // create the file
    [fileManager moveItemAtPath:urlForClickedRow.path toPath:savePanel.URL.path error:NULL];
    
    // reload file navigator, and select the new file
    [self flushCache];
    [self.filesView reloadData];
    [self revealFileInNavigator:savePanel.URL];
  }];
}

- (IBAction)moveFileToTrash:(id)sender
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  // find the target row
  NSInteger clickedRow = [self.filesView clickedRow];
  if (clickedRow == -1) {
    NSBeep();
    return;
  }
  NSURL *urlForClickedRow = [self.filesView itemAtRow:clickedRow];
  
  // move to trash
  [fileManager trashItemAtURL:urlForClickedRow resultingItemURL:NULL error:NULL];
  
  // reload file navigator, and select the new file
  [self flushCache];
  [self.filesView reloadData];
}

- (IBAction)newFolder:(id)sender
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  // find the target row
  NSURL *parentDir;
  NSInteger clickedRow = [self.filesView clickedRow];
  if (clickedRow == -1) {
    parentDir = self.rootURL;
  } else {
    NSURL *urlForClickedRow = [self.filesView itemAtRow:clickedRow];
    
    
    // figure out the parent dir (if selected row is a directory, make it a child. otherwise a sibling)
    BOOL clickedRowIsDir;
    BOOL clickedRowExists = [fileManager fileExistsAtPath:urlForClickedRow.path isDirectory:&clickedRowIsDir];
    if (!clickedRowExists) {
      NSBeep();
      return;
    }
    parentDir = clickedRowIsDir ? urlForClickedRow : urlForClickedRow.URLByDeletingLastPathComponent;
  }
  
  // show save panel
  NSSavePanel *savePanel = [NSSavePanel savePanel];
  savePanel.showsHiddenFiles = YES;
  savePanel.directoryURL = parentDir;
  [savePanel beginSheetModalForWindow:self.filesView.window completionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelCancelButton)
      return;
    
    // create the file
    [fileManager createDirectoryAtPath:savePanel.URL.path withIntermediateDirectories:NO attributes:nil error:NULL];
    
    // reload file navigator, and select the new file
    [self flushCache];
    [self.filesView reloadData];
    [self revealFileInNavigator:savePanel.URL];
  }];
}

- (void)revealFileInNavigator:(NSURL *)fileURL
{
  // walk down the tree starting at rootURL, untli we get to fileURL
  NSURL *nextUrl = self.rootURL;
  while (fileURL.pathComponents.count >= nextUrl.pathComponents.count) {
    // make sure nextDir is in our cache
    if (![self.cachedUrls containsObject:nextUrl]) {
      [self cacheDidMiss:nextUrl waitUntilFinished:1000]; // wait 1 second for the cache to fill
    }
    
    // is it in the cache now?
    if (![self.cachedUrls containsObject:nextUrl]) {
      NSLog(@"cannot find %@ in %@ - not a child url or filesystem too slow.", fileURL, self.rootURL);
      NSBeep();
      return;
    }
    
    if (nextUrl != self.rootURL)
    {
      
      // find the row
      NSInteger rowIndex = 0;
      NSURL *rowItem = nil;
      while ((rowItem = [self.filesView itemAtRow:rowIndex])) {
        if ([rowItem.path isEqual:nextUrl.path]) {
          break;
        }
        rowIndex++;
      }
      
      // find it in the outline view
      if (!rowItem) {
        NSLog(@"cannot find %@ in files view. issue with NSURL isEqual?", nextUrl);
        NSBeep();
        return;
      }
      
      // got the target file? select it now
      if (fileURL.pathComponents.count == nextUrl.pathComponents.count) {
        [self.filesView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
        [self.filesView scrollRowToVisible:rowIndex];
        break;
      }
      
      // expand it
      [self.filesView expandItem:rowItem];
    }
    
    // go to the next url
    nextUrl = [nextUrl URLByAppendingPathComponent:[fileURL.pathComponents objectAtIndex:nextUrl.pathComponents.count]];
  }
}

- (IBAction)refreshFilesList:(id)sender
{
  [self flushCache];
  [self.filesView reloadData];
}

- (NSArray *)sortedFiles:(NSMutableArray *)urls
{
  // alphabetic sort
  NSArray *sorted;
  sorted = [urls sortedArrayUsingComparator:^NSComparisonResult(NSURL *a, NSURL *b) {
    return [a.lastPathComponent compare:b.lastPathComponent options:NSNumericSearch | NSCaseInsensitiveSearch];
  }];
  
  // check if folders on top is disabled
  if (![DuxPreferences navigatorFilesViewFoldersAtTop]) {
    return sorted;
  }
  
  // sort folders on top
  NSMutableArray *folders = [[NSMutableArray alloc] init];
  NSMutableArray *files = [[NSMutableArray alloc] init];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (NSURL *url in sorted) {
    BOOL isDir;
    if ([fileManager fileExistsAtPath:url.path isDirectory:&isDir]) {
      if (isDir) {
        [folders addObject:url];
      } else {
        [files addObject:url];
      }
    }
  }
  [folders addObjectsFromArray:files];
  sorted = [NSArray arrayWithArray:folders];
  return sorted;
}

- (void)fileSystemDidChange:(id)sender
{
  [self flushCache];
  [self.filesView reloadData];
}

- (void)stopFileSystemWatcher
{
  if (fsStream) {
    FSEventStreamStop(fsStream);
    FSEventStreamUnscheduleFromRunLoop(fsStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  }
}

@end

void fs_event_cb(ConstFSEventStreamRef stream,
                 void *userData,
                 size_t numEvents,
                 void *eventPaths,
                 const FSEventStreamEventFlags eventFlags[],
                 const FSEventStreamEventId eventIds[])
{
  [[NSNotificationCenter defaultCenter] postNotificationName:DuxFSEventNotification object:nil];
}


