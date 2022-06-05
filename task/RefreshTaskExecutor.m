#import "RefreshTaskExecutor.h"

#import "TreeRefresher.h"
#import "RefreshTaskInput.h"
#import "ScanTaskOutput.h"
#import "ProgressTracker.h"
#import "DirectoryItem.h"


NSString  *RefreshTaskAbortedEvent = @"refreshTaskAborted";

@implementation RefreshTaskExecutor

- (instancetype) init {
  if (self = [super init]) {
    taskLock = [[NSLock alloc] init];
    treeRefresher = nil;
  }
  return self;
}

- (void) dealloc {
  [taskLock release];

  NSAssert(treeRefresher==nil, @"treeRefresher should be nil.");

  [super dealloc];
}


- (void) prepareToRunTask {
  // Can be ignored because a one-shot object is used for running the task.
}

- (id) runTaskWithInput:(id)input {
  NSAssert( treeRefresher==nil, @"treeRefresher already set.");

  RefreshTaskInput  *myInput = input;

  [taskLock lock];
  treeRefresher = [[TreeRefresher alloc] initWithFilterSet: myInput.filterSet
                                                   oldTree: myInput.treeSource];
  [treeRefresher setFileSizeMeasure: myInput.fileSizeMeasure];
  [treeRefresher setPackagesAsFiles: myInput.packagesAsFiles];
  [taskLock unlock];
  
  NSDate  *startTime = [NSDate date];
  
  TreeContext*  scanTree = [treeRefresher buildTreeForPath: myInput.treeSource.systemPath];
  ScanTaskOutput  *scanResult = nil;

  if (scanTree != nil) {
    NSLog(@"Done refreshing: %d folders scanned (%d skipped) in %.2fs.",
            [self.progressInfo[NumFoldersProcessedKey] intValue],
            [self.progressInfo[NumFoldersSkippedKey] intValue],
            -startTime.timeIntervalSinceNow);
    scanResult = [ScanTaskOutput scanTaskOutput: scanTree alert: treeRefresher.alertMessage];
  }
  else {
    if (treeRefresher.alertMessage != nil) {
      NSLog(@"Refresh failed.");
      scanResult = [ScanTaskOutput failedScanTaskOutput: treeRefresher.alertMessage];
    } else {
      NSLog(@"Refresh aborted.");
      [[NSNotificationCenter defaultCenter] postNotificationName: RefreshTaskAbortedEvent
                                                          object: self];
    }
  }

  [taskLock lock];
  [treeRefresher release];
  treeRefresher = nil;
  [taskLock unlock];

  return scanResult;
}

- (void) abortTask {
  [treeRefresher abort];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeRefresher is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = treeRefresher.progressInfo;
  [taskLock unlock];

  return dict;
}

@end
