#import "ScanTaskExecutor.h"

#import "TreeBuilder.h"
#import "ScanTaskInput.h"
#import "ProgressTracker.h"


@implementation ScanTaskExecutor

- (id) init {
  if (self = [super init]) {
    taskLock = [[NSLock alloc] init];
    treeBuilder = nil;
  }
  return self;
}

- (void) dealloc {
  [taskLock release];
  
  NSAssert(treeBuilder==nil, @"treeBuilder should be nil.");
  
  [super dealloc];
}


- (void) prepareToRunTask {
  // Can be ignored because a one-shot object is used for running the task.
}

- (id) runTaskWithInput: (id) input {
  NSAssert( treeBuilder==nil, @"treeBuilder already set.");

  ScanTaskInput  *myInput = input;

  [taskLock lock];
  treeBuilder = [[TreeBuilder alloc] initWithFilterSet: [input filterSet]];
  [treeBuilder setFileSizeMeasure: [myInput fileSizeMeasure]];
  [treeBuilder setPackagesAsFiles: [myInput packagesAsFiles]];
  [taskLock unlock];
  
  NSDate  *startTime = [NSDate date];
  
  TreeContext*  scanResult = 
    [treeBuilder buildTreeForPath: [myInput pathToScan]];
  
  if (scanResult != nil) {
    NSLog(@"Done scanning: %lu folders scanned (containing %lu files) in %.2fs.",
            [treeBuilder numFoldersScanned],
            [treeBuilder numFilesScanned],
            -[startTime timeIntervalSinceNow]);
  }
  else {
    NSLog(@"Scanning aborted.");
  }
  
  [taskLock lock];
  [treeBuilder release];
  treeBuilder = nil;
  [taskLock unlock];

  return scanResult;
}

- (void) abortTask {
  [treeBuilder abort];
}


- (NSDictionary *)progressInfo {
  NSDictionary  *dict;

  [taskLock lock];
  // The "taskLock" ensures that when treeBuilder is not nil, the object will
  // always be valid when it is used (i.e. it won't be deallocated).
  dict = [treeBuilder progressInfo];
  [taskLock unlock];
  
  return dict;
}

@end
