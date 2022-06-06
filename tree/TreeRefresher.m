#import "TreeRefresher.h"

#import "DirectoryItem.h"
#import "TreeConstants.h"
#import "TreeBalancer.h"
#import "FilteredTreeGuide.h"
#import "ScanProgressTracker.h"

@interface TreeRefresher (PrivateMethods)

- (void) refreshItemTree:(DirectoryItem *)oldDir
                    into:(DirectoryItem *)newDir;

- (void) refreshViaFullRescanItemTree:(DirectoryItem *)oldDir
                                 into:(DirectoryItem *)newDir;

- (void) refreshViaShallowRescanItemTree:(DirectoryItem *)oldDir
                                    into:(DirectoryItem *)newDir;

- (void) refreshViaShallowCopyItemTree:(DirectoryItem *)oldDir
                                  into:(DirectoryItem *)newDir;

@end // @interface TreeRefresher (PrivateMethods)


@implementation TreeRefresher

- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal {
  NSAssert(NO, @"Use initWithFilterSet:oldTree: instead");
  return [self initWithFilterSet: nil oldTree: nil];
}

- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal
                           oldTree:(DirectoryItem *)oldTreeVal {
  if (self = [super initWithFilterSet: filterSetVal]) {
    oldTree = [oldTreeVal retain];
  }
  return self;
}

- (void) dealloc {
  [oldTree release];

  [super dealloc];
}

@end // @implementation TreeRefresher

@implementation TreeRefresher (ProtectedMethods)

/* Constructs a tree for the given folder. It is used to implement buildTreeForPath:
 *
 * Overrides method in parent class to provide refresh implementation.
 */
- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path {
  [self refreshItemTree: oldTree into: dirItem];

  return !abort;
}

@end // @implementation TreeRefresher (ProtectedMethods)

@implementation TreeRefresher (PrivateMethods)

- (void) refreshItemTree:(DirectoryItem *)oldDir
                    into:(DirectoryItem *)newDir {
  NSAssert([oldDir.label isEqualToString: newDir.label] , @"Label mismatch");

  if (abort) return;

  if ((oldDir.rescanFlags & DirectoryNeedsFullRescan) != 0) {
    [self refreshViaFullRescanItemTree: oldDir into: newDir];
  }
  else if ((oldDir.rescanFlags & DirectoryNeedsShallowRescan) != 0) {
    [self refreshViaShallowRescanItemTree: oldDir into: newDir];
  }
  else {
    [self refreshViaShallowCopyItemTree: oldDir into: newDir];
  }
}

- (void) refreshViaFullRescanItemTree:(DirectoryItem *)oldDir
                                 into:(DirectoryItem *)newDir {
  NSString  *path = newDir.systemPath;

  NSLog(@"Full rescan of %@", path);
  [self scanTreeForDirectory: newDir atPath: path];
}


- (void) refreshViaShallowRescanItemTree:(DirectoryItem *)oldDir
                                    into:(DirectoryItem *)newDir {
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];
  NSString  *path = newDir.systemPath;

  NSLog(@"Shallow rescan of %@", path);

  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: newDir];

  // Perform shallow rescan
  [self getContentsForDirectory: newDir atPath: path dirs: dirs files: files];
  [progressTracker setNumSubFolders: dirs.count];

  // Gather the old directories
  NSMutableDictionary  *oldSubDirs = [NSMutableDictionary dictionary];
  [CompoundItem visitLeavesMaybeNil: oldDir.directoryItems
                           callback: ^(FileItem *dir) {
    oldSubDirs[dir.label] = dir;
  }];

  // Populate the contents of all sub-directories
  for (NSUInteger i = dirs.count; i-- > 0; ) {
    DirectoryItem  *newSubDir = dirs[i];
    DirectoryItem  *oldSubDir = oldSubDirs[newSubDir.label];

    if (oldSubDir != nil) {
      [self refreshItemTree: oldSubDir into: newSubDir];
    } else {
      [self scanTreeForDirectory: newSubDir atPath: newSubDir.systemPath];
    }
  }

  [newDir setFileItems: [treeBalancer createTreeForItems: files]
        directoryItems: [treeBalancer createTreeForItems: dirs]];

  [treeGuide emergedFromDirectory: newDir];
  [progressTracker processedFolder: newDir];

  // Do not polute auto-release pool
  [dirs release];
  [files release];
}

- (void) refreshViaShallowCopyItemTree:(DirectoryItem *)oldDir
                                  into:(DirectoryItem *)newDir {
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];

  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: newDir];

  [CompoundItem visitLeavesMaybeNil: oldDir.fileItems
                           callback: ^(FileItem *file) {
    [files addObject: file];
  }];
  for (NSUInteger i = files.count; i-- > 0; ) {
    PlainFileItem  *oldFile = files[i];
    PlainFileItem  *newFile = (PlainFileItem *)[oldFile duplicateFileItem: newDir];

    files[i] = newFile;
  }

  [CompoundItem visitLeavesMaybeNil: oldDir.directoryItems
                           callback: ^(FileItem *dir) {
    [dirs addObject: dir];
  }];
  [progressTracker setNumSubFolders: dirs.count];

  for (NSUInteger i = dirs.count; i-- > 0; ) {
    DirectoryItem  *oldSubDir = dirs[i];
    DirectoryItem  *newSubDir = (DirectoryItem *)[oldSubDir duplicateFileItem: newDir];

    [self refreshItemTree: oldSubDir into: newSubDir];

    dirs[i] = newSubDir;
  }

  [newDir setFileItems: [treeBalancer createTreeForItems: files]
        directoryItems: [treeBalancer createTreeForItems: dirs]];

  [treeGuide emergedFromDirectory: newDir];
  [progressTracker processedFolder: newDir];

  // Do not polute auto-release pool
  [dirs release];
  [files release];
}

@end // @implementation TreeRefresher (PrivateMethods)
