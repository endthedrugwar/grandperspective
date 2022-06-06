#import "TreeFilter.h"

#import "TreeConstants.h"
#import "PlainFileItem.h"
#import "ScanTreeRoot.h"
#import "CompoundItem.h"
#import "TreeContext.h"
#import "FilterSet.h"
#import "FilteredTreeGuide.h"
#import "TreeBalancer.h"

#import "TreeVisitingProgressTracker.h"


@interface TreeFilter (PrivateMethods)

- (void) filterItemTree:(DirectoryItem *)oldDirItem
                   into:(DirectoryItem *)newDirItem;

@end // @interface TreeFilter (PrivateMethods)


@implementation TreeFilter

- (instancetype) init {
  NSAssert(NO, @"Use initWithFilterSet: instead");
  return [self initWithFilterSet: nil];
}

- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal {
  if (self = [super init]) {
    filterSet = [filterSetVal retain];

    treeGuide = [[FilteredTreeGuide alloc] initWithFileItemTest: filterSet.fileItemTest];
    treeBalancer = [[TreeBalancer alloc] init];
    
    abort = NO;
    
    progressTracker = [[TreeVisitingProgressTracker alloc] init];
  }

  return self;
}

- (void) dealloc {
  [filterSet release];
  [treeGuide release];
  [treeBalancer release];

  [progressTracker release];
  
  [super dealloc];
}


- (BOOL) packagesAsFiles {
  return [treeGuide packagesAsFiles];
}

- (void) setPackagesAsFiles:(BOOL) flag {
  [treeGuide setPackagesAsFiles: flag];
}


- (TreeContext *)filterTree: (TreeContext *)oldTree {
  DirectoryItem  *oldScanTree = oldTree.scanTree;
  NSString  *pathToMonitor = oldTree.monitorsSource ? oldScanTree.systemPath : nil;

  TreeContext  *filterResult =
    [[[TreeContext alloc] initWithVolumePath: oldTree.volumeTree.systemPath
                             fileSizeMeasure: oldTree.fileSizeMeasure
                                  volumeSize: oldTree.volumeSize
                                   freeSpace: oldTree.freeSpace
                                   filterSet: filterSet
                                    scanTime: oldTree.scanTime
                                 monitorPath: pathToMonitor] autorelease];

  DirectoryItem  *scanTree = [ScanTreeRoot allocWithZone: Item.zoneForTree];
  [[scanTree initWithLabel: oldScanTree.label
                    parent: filterResult.scanTreeParent
                     flags: oldScanTree.fileItemFlags
              creationTime: oldScanTree.creationTime
          modificationTime: oldScanTree.modificationTime
                accessTime: oldScanTree.accessTime] autorelease];

  [progressTracker startingTask];
  
  [self filterItemTree: oldScanTree into: scanTree];

  [progressTracker finishedTask];

  [filterResult setScanTree: scanTree];

  return abort ? nil : filterResult;
}

- (void) abort {
  abort = YES;
}


- (NSDictionary *) progressInfo {
  // To be safe, do not return info when aborted. Auto-releasing parts of constructed tree could
  // invalidate path construction done by progressTracker. Even though it does not look that could
  // happen with current code, it could after some refactoring.
  return abort ? nil : [progressTracker progressInfo];
}

@end


@implementation TreeFilter (PrivateMethods)

- (void) filterItemTree:(DirectoryItem *)oldDir into:(DirectoryItem *)newDir {
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  
  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: oldDir];

  // Flatten and filter file children
  [CompoundItem visitLeavesMaybeNil: oldDir.fileItems
                           callback: ^(FileItem *file) {
    if ( [treeGuide includeFileItem: file] ) {
      [files addObject: file];
    }
  }];

  // Flatten and filter directory children
  [CompoundItem visitLeavesMaybeNil: oldDir.directoryItems
                           callback: ^(FileItem *dir) {
    if ([treeGuide includeFileItem: dir]) {
      [dirs addObject: dir];
    } else {
      [progressTracker skippedFolder: (DirectoryItem *)dir];
    }
  }];

  if (!abort) { // Break recursion when task has been aborted.
    NSUInteger  i;
  
    // Collect all file items that passed the test
    for (i = files.count; i-- > 0; ) {
      PlainFileItem  *oldFile = files[i];
      PlainFileItem  *newFile = (PlainFileItem *)[oldFile duplicateFileItem: newDir];
      
      files[i] = newFile;
    }
  
    // Filter the contents of all directory items
    for (i = dirs.count; i-- > 0; ) {
      DirectoryItem  *oldSubDir = dirs[i];
      DirectoryItem  *newSubDir = (DirectoryItem *)[oldSubDir duplicateFileItem: newDir];
      
      [self filterItemTree: oldSubDir into: newSubDir];
    
      if (! abort) {
        // Check to prevent inserting corrupt tree when filtering was aborted.
        
        dirs[i] = newSubDir;
      }
    }
  
    [newDir setFileItems: [treeBalancer createTreeForItems: files]
          directoryItems: [treeBalancer createTreeForItems: dirs]];
  }
  
  [treeGuide emergedFromDirectory: newDir];
  [progressTracker processedFolder: oldDir];
  
  [dirs release];
  [files release];
}

@end
