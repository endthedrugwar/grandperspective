#import "TreeRefresher.h"

#import "DirectoryItem.h"
#import "TreeConstants.h"
#import "TreeBalancer.h"

@interface TreeRefresher (PrivateMethods)

- (BOOL) refreshItemTree:(DirectoryItem *)oldDir
                    into:(DirectoryItem *)newDir;

- (BOOL) refreshViaFullRescanItemTree:(DirectoryItem *)oldDir
                                 into:(DirectoryItem *)newDir;

- (BOOL) refreshViaShallowRescanItemTree:(DirectoryItem *)oldDir
                                    into:(DirectoryItem *)newDir;

- (BOOL) refreshViaShallowCopyItemTree:(DirectoryItem *)oldDir
                                  into:(DirectoryItem *)newDir;

- (BOOL) addSiblings:(Item *)item toLookup:(NSMutableDictionary *)lookup;
- (BOOL) addSiblings:(Item *)item toArray:(NSMutableArray *)array;

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

- (BOOL) refreshItemTree:(DirectoryItem *)oldDir
                    into:(DirectoryItem *)newDir {
  NSAssert([oldDir.label isEqualToString: newDir.label] , @"Label mismatch");

  if ((oldDir.rescanFlags & DirectoryNeedsFullRescan) != 0) {
    if (![self refreshViaFullRescanItemTree: oldDir into: newDir]) {
      return NO;
    }
  }
  else if ((oldDir.rescanFlags & DirectoryNeedsShallowRescan) != 0) {
    if (![self refreshViaShallowRescanItemTree: oldDir into: newDir]) {
      return NO;
    }
  }
  else {
    if (![self refreshViaShallowCopyItemTree: oldDir into: newDir]) {
      return NO;
    }
  }

  return YES;
}

- (BOOL) refreshViaFullRescanItemTree:(DirectoryItem *)oldDir
                                 into:(DirectoryItem *)newDir {
  NSString  *path = newDir.systemPath;

  NSLog(@"Full rescan of %@", path);
  return [self scanTreeForDirectory: newDir atPath: path];
}


- (BOOL) refreshViaShallowRescanItemTree:(DirectoryItem *)oldDir
                                    into:(DirectoryItem *)newDir {
  NSMutableArray  *dirs = [NSMutableArray arrayWithCapacity: INITIAL_DIRS_CAPACITY];
  NSMutableArray  *files = [NSMutableArray arrayWithCapacity: INITIAL_FILES_CAPACITY];
  NSString  *path = newDir.systemPath;

  NSLog(@"Shallow rescan of %@", path);

  // Perform shallow rescan
  if (![self getContentsForDirectory: newDir
                              atPath: path
                                dirs: dirs
                               files: files]) {
    return NO;
  }

  // Gather the old directories
  id  oldSubDirs = [NSMutableDictionary dictionary];
  if (oldDir.directoryItems != nil &&
      ![self addSiblings: oldDir.directoryItems toLookup: oldSubDirs]) {
    return NO;
  }

  // Populate the contents of all sub-directories
  for (NSUInteger i = dirs.count; i-- > 0; ) {
    DirectoryItem  *newSubDir = dirs[i];
    DirectoryItem  *oldSubDir = oldSubDirs[newSubDir.label];

    if (oldSubDir != nil) {
      if (![self refreshItemTree: oldSubDir into: newSubDir]) {
        return NO;
      }
    } else {
      if (![self scanTreeForDirectory: newSubDir atPath: newSubDir.systemPath]) {
        return NO;
      }
    }
  }

  [newDir setFileItems: [treeBalancer createTreeForItems: files]
        directoryItems: [treeBalancer createTreeForItems: dirs]];

  return YES;
}

- (BOOL) refreshViaShallowCopyItemTree:(DirectoryItem *)oldDir
                                  into:(DirectoryItem *)newDir {
  NSMutableArray  *files = [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY];
  NSMutableArray  *dirs = [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY];

  if (oldDir.fileItems != nil
      && ![self addSiblings: oldDir.fileItems toArray: files]) {
    return NO;
  }
  for (NSUInteger i = files.count; i-- > 0; ) {
    PlainFileItem  *oldFile = files[i];
    PlainFileItem  *newFile = (PlainFileItem *)[oldFile duplicateFileItem: newDir];

    files[i] = newFile;
  }

  if (oldDir.directoryItems != nil
      && ![self addSiblings: oldDir.directoryItems toArray: dirs]) {
    return NO;
  }
  for (NSUInteger i = dirs.count; i-- > 0; ) {
    DirectoryItem  *oldSubDir = dirs[i];
    DirectoryItem  *newSubDir = (DirectoryItem *)[oldSubDir duplicateFileItem: newDir];

    if (![self refreshItemTree: oldSubDir into: newSubDir]) {
      return NO;
    }

    dirs[i] = newSubDir;
  }

  [newDir setFileItems: [treeBalancer createTreeForItems: files]
        directoryItems: [treeBalancer createTreeForItems: dirs]];

  return YES;
}

- (BOOL) addSiblings:(Item *)item toLookup:(NSMutableDictionary *)lookup {
  if (abort) {
    return NO;
  }

  if (item.isVirtual) {
    [self addSiblings: ((CompoundItem *)item).first toLookup: lookup];
    [self addSiblings: ((CompoundItem *)item).second toLookup: lookup];
  }
  else {
    lookup[((FileItem *)item).label] = item;
  }

  return YES;
}

- (BOOL) addSiblings:(Item *)item toArray:(NSMutableArray *)array {
  if (abort) {
    return NO;
  }

  if (item.isVirtual) {
    [self addSiblings: ((CompoundItem *)item).first toArray: array];
    [self addSiblings: ((CompoundItem *)item).second toArray: array];
  }
  else {
    [array addObject: item];
  }

  return YES;
}

@end // @implementation TreeRefresher (PrivateMethods)
