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

- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal {
  if (self = [super init]) {
    filterSet = [filterSetVal retain];

    treeGuide = [[FilteredTreeGuide alloc] initWithFileItemTest: filterSet.fileItemTest];
    [treeGuide setPackagesAsFiles: filterSet.packagesAsFiles];

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

  DirectoryItem  *scanTree = [ScanTreeRoot alloc];
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
  return abort ? nil : progressTracker.progressInfo;
}

@end


@implementation TreeFilter (PrivateMethods)

- (void) filterItemTree:(DirectoryItem *)oldDir into:(DirectoryItem *)newDir {
  // Break recursion when task has been aborted.
  if (abort) return;
  
  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: oldDir];

  // Collect file children that pass the filter test
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.fileItems
                                     callback: ^(FileItem *file) {
    if ([treeGuide includeFileItem: file]) {
      [newDir addFile: [file duplicateFileItem: newDir]];
    }
  }];

  // Collect and populate directory children that pass the filter test
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.directoryItems
                                     callback: ^(FileItem *oldSubDir) {
    if ([treeGuide includeFileItem: oldSubDir]) {
      DirectoryItem  *newSubDir = (DirectoryItem *)[oldSubDir duplicateFileItem: newDir];
      [self filterItemTree: (DirectoryItem *)oldSubDir into: newSubDir];

      if (! abort) {
        // Check to prevent inserting corrupt tree when filtering was aborted.
        [newDir addSubdir: newSubDir];
      }
    } else {
      [progressTracker skippedFolder: (DirectoryItem *)oldSubDir];
    }
  }];

  if (!abort) {
    [newDir setSize];
    [newDir balanceTree: treeBalancer];
  }
  
  [treeGuide emergedFromDirectory: newDir];
  [progressTracker processedFolder: oldDir];
}

@end
