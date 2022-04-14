#import "ProgressTracker.h"

#import "DirectoryItem.h"
#import "PreferencesPanelControl.h"

NSString  *NumFoldersProcessedKey = @"numFoldersProcessed";
NSString  *NumFoldersSkippedKey = @"numFoldersSkipped";
NSString  *CurrentFolderPathKey = @"currentFolderPath";
NSString  *StableFolderPathKey = @"stableFolderPath";
NSString  *EstimatedProgressKey = @"estimatedProgress";


@implementation ProgressTracker

- (instancetype) init {
  if (self = [super init]) {
    mutex = [[NSLock alloc] init];
    directoryStack = [[NSMutableArray alloc] initWithCapacity: 16];

    NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
    stableTimeInterval = [userDefaults floatForKey: ProgressPanelStableTimeKey];
    if (stableTimeInterval <= 0) {
      NSLog(@"Invalid value for stableTimeInterval");
      stableTimeInterval = 1;
    }
  }

  return self;
}

- (void) dealloc {
  [mutex release];
  [directoryStack release];
  [rootItem release];
  
  [super dealloc];

}

- (void) startingTask {
  [mutex lock];
  numFoldersProcessed = 0;
  numFoldersSkipped = 0;
  level = 0;
  [rootItem release];
  rootItem = nil;
  [directoryStack removeAllObjects];
  [mutex unlock];
}

- (void) finishedTask {
  [mutex lock];
  [directoryStack removeAllObjects];
  [mutex unlock];
}


- (void) processingFolder:(DirectoryItem *)dirItem {
  [mutex lock];
  [self _processingFolder: dirItem];
  [mutex unlock];
}

- (void) processedFolder:(DirectoryItem *)dirItem {
  [mutex lock];
  [self _processedFolder: dirItem];
  [mutex unlock];
}

- (void) skippedFolder:(DirectoryItem *)dirItem {
  [mutex lock];
  [self _skippedFolder: dirItem];
  [mutex unlock];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [mutex lock];
  // Find the stable folder, the deepest folder that been processed for more than the configured
  // time interval
  DirectoryItem  *stableFolder = rootItem;
  if (level > 0) {
    NSUInteger  stableLevel = 0;
    NSUInteger  maxLevel = MIN(level, NUM_PROGRESS_ESTIMATE_LEVELS) - 1;
    CFAbsoluteTime refTime = CFAbsoluteTimeGetCurrent() - stableTimeInterval;
    while (stableLevel < maxLevel && entryTime[stableLevel + 1] < refTime) {
      ++stableLevel;
    }
    stableFolder = [directoryStack objectAtIndex: stableLevel];
  }

  dict = @{NumFoldersProcessedKey: @(numFoldersProcessed),
           NumFoldersSkippedKey: @(numFoldersSkipped),
           CurrentFolderPathKey: [directoryStack.lastObject path] ?: @"",
           StableFolderPathKey: [stableFolder path] ?: @"",
           EstimatedProgressKey: @([self estimatedProgress])};
  [mutex unlock];

  return dict;
}

- (NSUInteger) numFoldersProcessed {
  return numFoldersProcessed;
}

@end // @implementation ProgressTracker


@implementation ProgressTracker (ProtectedMethods)

- (void) _processingFolder:(DirectoryItem *)dirItem {
  if (rootItem == nil) {
    // Find the root of the tree
    DirectoryItem  *parent;
    rootItem = dirItem;
    while ((parent = [rootItem parentDirectory]) != nil) {
      rootItem = parent;
    }

    // Retain the root of the tree. This ensures that -path can be called for any FileItem in the
    // stack, even after the tree has been released externally (e.g. because the task constructing
    // it has been aborted).
    [rootItem retain];
  }

  [directoryStack addObject: dirItem];
  if (level < NUM_PROGRESS_ESTIMATE_LEVELS) {
    entryTime[level] = CFAbsoluteTimeGetCurrent();
  }
  level++;
}

- (void) _processedFolder:(DirectoryItem *)dirItem {
  NSAssert([directoryStack lastObject] == dirItem, @"Inconsistent stack.");
  [directoryStack removeLastObject];
  numFoldersProcessed++;
  level--;
}

- (void) _skippedFolder:(DirectoryItem *)dirItem {
  numFoldersSkipped++;
}

/* Default implementation, fixed to zero. Without more detailed knowledge about
 * the task, it is not feasible to estimate progress accurately.
 */
- (float) estimatedProgress {
  return 0.0;
}

@end
