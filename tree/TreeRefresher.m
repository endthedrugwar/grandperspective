#import "TreeRefresher.h"

#import "AlertMessage.h"
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

- (BOOL) deepHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir;
- (BOOL) shallowHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir;

@end // @interface TreeRefresher (PrivateMethods)


@implementation TreeRefresher

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
  hardLinkMismatch = NO;

  [self refreshItemTree: oldTree into: dirItem];

  return !abort;
}

- (AlertMessage *)createAlertMessage:(DirectoryItem *)scanTree {
  if (hardLinkMismatch) {
    AlertMessage  *alert = [[[AlertMessage alloc] init] autorelease];
    alert.messageText = NSLocalizedString
      (@"Inaccuracies in hard-linked folder contents", @"Alert message");
    alert.informativeText = NSLocalizedString
      (@"The refreshed content may not be fully accurate. Hard-linked items may occur more than once or could be missing. Perform a rescan to ensure that each hard-linked item occurs only once.",
       @"Alert message");
    return alert;
  }

  return [super createAlertMessage: scanTree];
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

  if (!hardLinkMismatch && ![self deepHardlinkCompare: oldDir to: newDir]) {
    NSLog(@"Deep hardlink mismatch at %@", path);
    hardLinkMismatch = true;
  }
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
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.directoryItems
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

  if (!hardLinkMismatch && ![self shallowHardlinkCompare: oldDir to: newDir]) {
    NSLog(@"Shallow hardlink mismatch at %@", path);
    hardLinkMismatch = true;
  }

  // Do not pollute auto-release pool
  [dirs release];
  [files release];
}

- (void) refreshViaShallowCopyItemTree:(DirectoryItem *)oldDir
                                  into:(DirectoryItem *)newDir {
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];

  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: newDir];

  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.fileItems
                                     callback: ^(FileItem *file) {
    [files addObject: file];
  }];
  for (NSUInteger i = files.count; i-- > 0; ) {
    PlainFileItem  *oldFile = files[i];
    PlainFileItem  *newFile = (PlainFileItem *)[oldFile duplicateFileItem: newDir];

    files[i] = newFile;
  }

  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.directoryItems
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

- (BOOL) deepHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir {
  NSMutableSet  *oldSet = [[NSMutableSet alloc] init];
  NSMutableSet  *newSet = [[NSMutableSet alloc] init];

  // Find hard-linked items in the old directory
  [oldDir visitFileItemDescendants: ^(FileItem *file) {
    if (file.isHardLinked) {
      [oldSet addObject: file.label];
    }
  }];

  // Find hard-linked items in the old directory
  [newDir visitFileItemDescendants: ^(FileItem *file) {
    if (file.isHardLinked) {
      [newSet addObject: file.label];
    }
  }];

  BOOL  equal = [oldSet isEqualToSet: newSet];

  [oldSet release];
  [newSet release];

  return equal;
}

- (BOOL) shallowHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir {
  NSMutableSet  *oldSet = [[NSMutableSet alloc] init];
  NSMutableSet  *newSet = [[NSMutableSet alloc] init];

  // Find hard-linked items in the old directory
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.childItems
                                     callback: ^(FileItem *file) {
    if (file.isHardLinked) {
      [oldSet addObject: file.label];
    }
  }];

  // Find hard-linked items in the old directory
  [CompoundItem visitFileItemChildrenMaybeNil: newDir.childItems
                                     callback: ^(FileItem *file) {
    if (file.isHardLinked) {
      [newSet addObject: file.label];
    }
  }];

  BOOL  equal = [oldSet isEqualToSet: newSet];

  [oldSet release];
  [newSet release];

  return equal;
}

@end // @implementation TreeRefresher (PrivateMethods)
