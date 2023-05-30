#import "TreeBuilder.h"

#include <fts.h>
#include <sys/stat.h>

#import "AlertMessage.h"
#import "TreeConstants.h"
#import "PlainFileItem.h"
#import "DirectoryItem.h"
#import "ScanTreeRoot.h"
#import "CompoundItem.h"
#import "TreeContext.h"
#import "FilterSet.h"
#import "FilteredTreeGuide.h"
#import "TreeBalancer.h"
#import "NSURL.h"
#import "ControlConstants.h"

#import "ScanProgressTracker.h"
#import "UniformType.h"
#import "UniformTypeInventory.h"


NSString  *LogicalFileSizeName = @"logical";
NSString  *PhysicalFileSizeName = @"physical";
NSString  *TallyFileSizeName = @"tally";


/* Use smaller bounds given the extra scan cost needed to determine the number of directories
 * at each level used for tracking progress.
 */
#define  NUM_SCAN_PROGRESS_ESTIMATE_LEVELS MIN(6, NUM_PROGRESS_ESTIMATE_LEVELS)

#define  AUTORELEASE_PERIOD  1024

/* Helper class that is used to temporarily store additional info for directories that are being
 * scanned. It stores the info that is not maintained by the DirectoryItem class yet is needed
 * while its contents are still being scanned.
 */
@interface ScanStackFrame : NSObject {
@public
  DirectoryItem  *dirItem;

  FTSENT  *entp;

  // Arrays containing the immediate children
  NSMutableArray<DirectoryItem *>  *dirs;
  NSMutableArray<PlainFileItem *>  *files;
}

- (instancetype) initWithDirs:(NSMutableArray<DirectoryItem *> *)dirs
                        files:(NSMutableArray<PlainFileItem *> *)files NS_DESIGNATED_INITIALIZER;

// Convenience "constructor" for repeated usage
- (void) initWithDirectoryItem:(DirectoryItem *)dirItem entp:(FTSENT *)entp;

/* Remove any sub-directories that should not be included according to the treeGuide. This
 * filtering needs to be done after all items inside this directory have been scanned, as the
 * filtering may be based on the (recursive) size of the items.
 */
- (void) filterSubDirectories:(FilteredTreeGuide *)treeGuide;

@end // @interface ScanStackFrame


@interface TreeBuilder (PrivateMethods)

+ (ITEM_SIZE) getLogicalFileSize:(FTSENT *)entp withType:(UniformType *)fileType;

- (void) addToStack:(DirectoryItem *)dirItem entp:(FTSENT *)entp;

- (BOOL) unwindStackToParent:(FTSENT *)entp;
- (BOOL) popFromStack:(FTSENT *)entp;

- (void) finalizeStackFrame:(ScanStackFrame *)stackFrame;

- (BOOL) visitItem:(FTSENT *)entp
            parent:(ScanStackFrame *)parent
           recurse:(BOOL)visitDescendants;
- (BOOL) visitHardLinkedItem:(FTSENT *)entp;

// Return the number of sub-folders of the (directory) item last returned by fts_read
- (int) determineNumSubFolders;

- (FTSENT *)startScan:(NSString *)path;
- (void) stopScan;

@end // @interface TreeBuilder (PrivateMethods)


CFAbsoluteTime convertTimespec(struct timespec ts) {
  // Ignore nanoseconds; we do not need sub-second accuracy
  return (CFAbsoluteTime)((CFTimeInterval)ts.tv_sec - kCFAbsoluteTimeIntervalSince1970);
}

@implementation ScanStackFrame

// Overrides super's designated initialiser.
- (instancetype) init {
  return [self initWithDirs: [[NSMutableArray alloc] initWithCapacity: INITIAL_DIRS_CAPACITY * 32]
                      files: [[NSMutableArray alloc] initWithCapacity: INITIAL_FILES_CAPACITY * 32]
  ];
}

- (instancetype) initWithDirs:(NSMutableArray<DirectoryItem *> *)dirsVal
                        files:(NSMutableArray<PlainFileItem *> *)filesVal {
  if (self = [super init]) {
    // Multiplying sizes specified in TreeConstants.h. As these arrays are being re-used, it is
    // better to make them initially larger to avoid unnecessary resizing.
    dirs = [dirsVal retain];
    files = [filesVal retain];
  }
  return self;
}

// "Constructor" intended for repeated usage. It assumes init has already been invoked
- (void) initWithDirectoryItem:(DirectoryItem *)dirItemVal entp:(FTSENT *)entpVal {
  if (dirItem != dirItemVal) {
    [dirItem release];
  }
  dirItem = [dirItemVal retain];

  entp = entpVal;

  // Clear data from previous usage
  [dirs removeAllObjects];
  [files removeAllObjects];
}

- (void) dealloc {
  [dirs release];
  [files release];

  entp = NULL;
  [dirItem release];
  
  [super dealloc];
}

- (DirectoryItem *) directoryItem {
  return dirItem;
}

- (void) filterSubDirectories:(FilteredTreeGuide *)treeGuide {
  for (NSUInteger i = dirs.count; i-- > 0; ) {
    DirectoryItem  *dirChildItem = dirs[i];

    if (! [treeGuide includeFileItem: dirChildItem] ) {
      // The directory did not pass the test, so exclude it.
      [dirs removeObjectAtIndex: i];
    }
  }
}

@end // @implementation ScanStackFrame


@implementation TreeBuilder

+ (NSArray *)fileSizeMeasureNames {
  static NSArray  *fileSizeMeasureNames = nil;

  if (fileSizeMeasureNames == nil) {
    fileSizeMeasureNames = [@[LogicalFileSizeName, PhysicalFileSizeName, TallyFileSizeName] retain];
  }
  
  return fileSizeMeasureNames;
}

- (instancetype) init {
  return [self initWithFilterSet: nil];
}


- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal {
  if (self = [super init]) {
    filterSet = [filterSetVal retain];

    treeGuide = [[FilteredTreeGuide alloc] initWithFileItemTest: filterSet.fileItemTest];
    [treeGuide setPackagesAsFiles: filterSet.packagesAsFiles];

    treeBalancer = [[TreeBalancer alloc] init];
    typeInventory = [UniformTypeInventory.defaultUniformTypeInventory retain];

    ftsp = NULL;

    hardLinkedFileNumbers = [[NSMutableSet alloc] initWithCapacity: 32];
    abort = NO;
    
    progressTracker =
      [[ScanProgressTracker alloc] initWithMaxLevel: NUM_SCAN_PROGRESS_ESTIMATE_LEVELS];
    
    dirStack = [[NSMutableArray alloc] initWithCapacity: 16];
    
    [self setFileSizeMeasure: LogicalFileSizeName];
    
    NSUserDefaults *args = NSUserDefaults.standardUserDefaults;
    debugLogEnabled = [args boolForKey: @"logAll"] || [args boolForKey: @"logScanning"];

    _alertMessage = nil;
  }
  return self;
}


- (void) dealloc {
  [filterSet release];

  [treeGuide release];
  [treeBalancer release];
  [typeInventory release];

  NSAssert(ftsp == NULL, @"ftsp not closed");

  [hardLinkedFileNumbers release];
  [fileSizeMeasureName release];
  
  [progressTracker release];
  
  [dirStack release];

  [_alertMessage release];
  
  [super dealloc];
}


- (NSString *)fileSizeMeasure {
  return fileSizeMeasureName;
}

- (void) setFileSizeMeasure:(NSString *)measure {
  if ([measure isEqualToString: LogicalFileSizeName]) {
    fileSizeMeasure = LogicalFileSize;
  }
  else if ([measure isEqualToString: PhysicalFileSizeName]) {
    fileSizeMeasure = PhysicalFileSize;
  }
  else if ([measure isEqualToString: TallyFileSizeName]) {
    fileSizeMeasure = TallyFileSize;
  }
  else {
    NSAssert(NO, @"Invalid file size measure.");
  }
  
  if (measure != fileSizeMeasureName) {
    [fileSizeMeasureName release];
    fileSizeMeasureName = [measure retain];
  }
}


- (void) abort {
  abort = YES;
}

- (TreeContext *)buildTreeForPath:(NSString *)path {
  TreeContext  *treeContext = [self treeContextForVolumeContaining: path];
  if (treeContext == nil) {
    return nil;
  }

  DirectoryItem  *scanTree = [self treeRootForPath: path context: treeContext];

  [progressTracker startingTask];

  BOOL  ok = [self buildTreeForDirectory: scanTree atPath: path];

  [progressTracker finishedTask];

  if (! ok) {
    return nil;
  }

  [treeContext setScanTree: scanTree];
  _alertMessage = [[self createAlertMessage: scanTree] retain];

  return treeContext;
}

- (NSDictionary *)progressInfo {
  // To be safe, do not return info when aborted. Auto-releasing parts of constructed tree could
  // invalidate path construction done by progressTracker. Even though it does not look that could
  // happen with current code, it could after some refactoring.
  return abort ? nil : progressTracker.progressInfo;
}

@end // @implementation TreeBuilder


@implementation TreeBuilder (ProtectedMethods)

- (TreeContext *)treeContextForVolumeContaining:(NSString *)path {
  NSURL  *url = [NSURL fileURLWithPath: path];

  if (!url.isDirectory) {
    // This may happen when the directory has been deleted (which can happen when rescanning)
    NSLog(@"Path to scan %@ is not a directory.", path);

    [_alertMessage release];

    _alertMessage = [[AlertMessage alloc] init];
    _alertMessage.messageText = NSLocalizedString(@"Scanning failed", @"Alert message");
    NSString *fmt = NSLocalizedString
      (@"The path %@ does not exist or is not a folder", @"Alert message");
    _alertMessage.informativeText = [NSString stringWithFormat: fmt, path];

    return nil;
  }

  NSError  *error = nil;
  NSURL  *volumeRoot;
  [url getResourceValue: &volumeRoot forKey: NSURLVolumeURLKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to determine volume root of %@: %@", url, error.description);
  }

  NSNumber  *freeSpace;
  [volumeRoot getResourceValue: &freeSpace forKey: NSURLVolumeAvailableCapacityKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to determine free space for %@: %@", volumeRoot, error.description);
  }

  NSNumber  *volumeSize;
  [volumeRoot getResourceValue: &volumeSize forKey: NSURLVolumeTotalCapacityKey error: &error];
  if (error != nil) {
    NSLog(@"Failed to determine capacity of %@: %@", volumeRoot, error.description);
  }

  return [[[TreeContext alloc] initWithVolumePath: volumeRoot.path
                                  fileSizeMeasure: fileSizeMeasureName
                                       volumeSize: volumeSize.unsignedLongLongValue
                                        freeSpace: freeSpace.unsignedLongLongValue
                                        filterSet: filterSet
                                      monitorPath: path] autorelease];
}

- (ScanTreeRoot *)treeRootForPath:(NSString *)path
                          context:(TreeContext *)treeContext {
  // Determine relative path
  NSString  *volumePath = treeContext.volumeTree.systemPathComponent;
  NSString  *relativePath =
    volumePath.length < path.length ? [path substringFromIndex: volumePath.length] : @"";
  if (relativePath.absolutePath) {
    // Strip leading slash.
    relativePath = [relativePath substringFromIndex: 1];
  }

  NSFileManager  *manager = NSFileManager.defaultManager;
  if (relativePath.length > 0) {
    NSLog(@"Scanning volume %@ [%@], starting at %@", volumePath,
          [manager displayNameAtPath: volumePath], relativePath);
  }
  else {
    NSLog(@"Scanning entire volume %@ [%@].", volumePath,
          [manager displayNameAtPath: volumePath]);
  }

  // Get the properties
  NSURL  *treeRootURL = [NSURL fileURLWithPath: path];
  FileItemOptions  flags = 0;
  if (treeRootURL.isPackage) {
    flags |= FileItemIsPackage;
  }
  if (treeRootURL.isHardLinked) {
    flags |= FileItemIsHardlinked;
  }

  ScanTreeRoot  *scanTree = [ScanTreeRoot allocWithZone: [Item zoneForTree]];
  [[scanTree initWithLabel: relativePath
                    parent: treeContext.scanTreeParent
                     flags: flags
              creationTime: treeRootURL.creationTime
          modificationTime: treeRootURL.modificationTime
                accessTime: treeRootURL.accessTime
    ] autorelease];

  // Reset other state
  totalPhysicalSize = 0;
  numOverestimatedFiles = 0;
  [hardLinkedFileNumbers removeAllObjects];
  [_alertMessage release];
  _alertMessage = nil;

  return scanTree;
}

- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path {
  return [self scanTreeForDirectory: dirItem atPath: path];
}

- (BOOL) scanTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path {
  NSAutoreleasePool  *autoreleasePool = nil;
  int  i = 0;
  BOOL  popped;
  dirStackTopIndex = -1;

  [self addToStack: dirItem entp: [self startScan: path]];

  @try {
    FTSENT *entp;
    while ((entp = fts_read(ftsp)) != NULL) {
      switch (entp->fts_info) {
        case FTS_DP:
          // Directory being visited a second time
          popped = [self popFromStack: entp];
          NSAssert1(popped, @"Failed to pop %s", entp->fts_path);
          continue;
        case FTS_DNR:
        case FTS_ERR:
        case FTS_NS:
          NSLog(@"Error reading directory %s: %s", entp->fts_path, strerror(entp->fts_errno));
          continue;
      }

      // Fail-safe unwind. This typically is not necessary due to pop on FTS_DP. However, it is
      // sometimes needed to recover from FTS errors.
      popped = [self unwindStackToParent: entp->fts_parent];
      NSAssert1(popped, @"Failed to unwind to %s", entp->fts_parent->fts_path);

      ScanStackFrame  *parent = dirStack[dirStackTopIndex];

      if (![self visitItem: entp parent: parent recurse: YES]) {
        fts_set(ftsp, entp, FTS_SKIP);
      }
      if (++i == AUTORELEASE_PERIOD) {
        [autoreleasePool release];
        autoreleasePool = [[NSAutoreleasePool alloc] init];
        i = 0;
      }
      if (abort) {
        return NO;
      }
    }

    if (dirStackTopIndex >= 0) {
      NSLog(@"Warning: Stack not fully unwound");

      popped = [self popFromStack: ((ScanStackFrame *)dirStack[0])->entp];
      NSAssert(popped, @"Final stack unwind failed?");
    }
  }
  @finally {
    [autoreleasePool release];
    [self stopScan];
  }

  return YES;
}

- (void) getContentsForDirectory:(DirectoryItem *)dirItem
                          atPath:(NSString *)path
                            dirs:(NSMutableArray<DirectoryItem *> *)dirs
                           files:(NSMutableArray<PlainFileItem *> *)files {
  ScanStackFrame  *parent = [[[ScanStackFrame alloc] initWithDirs: dirs files: files] autorelease];
  [parent initWithDirectoryItem: dirItem entp: [self startScan: path]];

  FTSENT *entp;
  while ((entp = fts_read(ftsp)) != NULL) {
    if (entp->fts_info == FTS_DP) continue; // Directory being visited a second time

    BOOL  isDirectory = S_ISDIR(entp->fts_statp->st_mode);
    [self visitItem: entp parent: parent recurse: NO];
    if (isDirectory) {
      fts_set(ftsp, entp, FTS_SKIP);
    }
  }

  [self stopScan];
}

- (AlertMessage *)createAlertMessage:(DirectoryItem *)scanTree {
  if (fileSizeMeasure == LogicalFileSize) {
    if (scanTree.itemSize > totalPhysicalSize) {
      AlertMessage  *alert = [[[AlertMessage alloc] init] autorelease];
      alert.messageText = NSLocalizedString
        (@"The reported total size is larger than the actual size on disk", @"Alert message");
      NSString *fmt = NSLocalizedString
        (@"The actual (physical) size is %.1f%% of the reported (logical) size. Consider rescanning using the Physical file size measure",
         @"Alert message");
      float percentage = (100.0 * totalPhysicalSize) / scanTree.itemSize;
      alert.informativeText = [NSString stringWithFormat: fmt, percentage];
      return alert;
    }

    if (numOverestimatedFiles > 0) {
      AlertMessage  *alert = [[[AlertMessage alloc] init] autorelease];
      alert.messageText = NSLocalizedString
        (@"The reported size of some files is larger than their actual size on disk",
         @"Alert message");
      NSString *fmt = NSLocalizedString
        (@"For %d files the reported (logical) size is larger than their actual (physical) size. Consider rescanning using the Physical file size measure",
         @"Alert message");
      alert.informativeText = [NSString stringWithFormat: fmt, numOverestimatedFiles];
      return alert;
    }
  }

  return nil;
}

@end // @implementation TreeBuilder (ProtectedMethods)


@implementation TreeBuilder (PrivateMethods)

+ (ITEM_SIZE) getLogicalFileSize:(FTSENT *)entp withType:(UniformType *)fileType {
  if ([fileType.uniformTypeIdentifier isEqualToString: @"com.apple.icloud-file-fault"]) {
    NSURL  *url = [NSURL fileURLWithFileSystemRepresentation: entp->fts_path
                                                 isDirectory: S_ISDIR(entp->fts_statp->st_mode)
                                               relativeToURL: NULL];
    NSDictionary  *dict = [NSDictionary dictionaryWithContentsOfURL: url];
    NSNumber  *fileSize = [dict objectForKey: @"NSURLFileSizeKey"];

    return fileSize.unsignedLongLongValue;
  } else {
    return entp->fts_statp->st_size;
  }
}

- (void) addToStack:(DirectoryItem *)dirItem entp:(FTSENT *)entp {
//  NSLog(@"Push: %s", entp->fts_path);

  // Expand stack if required
  if (dirStackTopIndex + 1 == (int)dirStack.count) {
    [dirStack addObject: [[[ScanStackFrame alloc] init] autorelease]];
  }
  
  // Add the item to the stack. Overwriting the previous entry.
  [dirStack[++dirStackTopIndex] initWithDirectoryItem: dirItem entp: entp];
  
  [treeGuide descendIntoDirectory: dirItem];
  [progressTracker processingFolder: dirItem];
  if (debugLogEnabled) {
    NSLog(@"Scanning %s", entp->fts_path);
  }
  if (dirStackTopIndex < NUM_SCAN_PROGRESS_ESTIMATE_LEVELS) {
    [progressTracker setNumSubFolders: [self determineNumSubFolders]];
  }
}

- (BOOL) unwindStackToParent:(FTSENT *)entp {
  while (dirStackTopIndex >= 0) {
    ScanStackFrame  *topDir = (ScanStackFrame *)dirStack[dirStackTopIndex];
    if (topDir->entp == entp) {
      return YES;
    }

    [self finalizeStackFrame: topDir];
    dirStackTopIndex--;
  }

  return NO;
}

- (BOOL) popFromStack:(FTSENT *)entp {
  while (dirStackTopIndex >= 0) {
    ScanStackFrame  *topDir = (ScanStackFrame *)dirStack[dirStackTopIndex--];

    [self finalizeStackFrame: topDir];
    if (topDir->entp == entp) {
      return YES;
    }
  }

  return NO;
}

- (void) finalizeStackFrame:(ScanStackFrame *)topDir {
//  NSLog(@"Pop: %s", topDir->entp->fts_path);

  [topDir filterSubDirectories: treeGuide];

  DirectoryItem  *dirItem = topDir->dirItem;

  [dirItem setFileItems: [treeBalancer createTreeForItems: topDir->files]
         directoryItems: [treeBalancer createTreeForItems: topDir->dirs]];

  [treeGuide emergedFromDirectory: dirItem];
  [progressTracker processedFolder: dirItem];
}

- (BOOL) visitItem:(FTSENT *)entp
            parent:(ScanStackFrame *)parent
           recurse:(BOOL)visitDescendants {
  FileItemOptions  flags = 0;
  struct stat  *statBlock = entp->fts_statp;
  BOOL  isDirectory = S_ISDIR(statBlock->st_mode);

  if (statBlock->st_nlink > 1) {
    flags |= FileItemIsHardlinked;

    if (![self visitHardLinkedItem: entp]) {
      // Do not visit descendants if the item was a directory
      if (isDirectory) {
        visitDescendants = NO;
      }

      return visitDescendants;
    }
  }
  
  // TODO: Alloc in parent.zone?
  NSString  *lastPathComponent = [NSString stringWithUTF8String: entp->fts_name];

  if (isDirectory) {
    // TODO: Speed up package check?
    NSURL  *url = [NSURL fileURLWithFileSystemRepresentation: entp->fts_path
                                                 isDirectory: YES
                                               relativeToURL: NULL];
    if (url.isPackage) {
      if (lastPathComponent.pathExtension.length == 0) {
        NSLog(@"Extension-less package: %s", entp->fts_path);
      }
      flags |= FileItemIsPackage;
    }
    
    DirectoryItem  *dirChildItem = [[DirectoryItem allocWithZone: parent.zone]
                                    initWithLabel: lastPathComponent
                                           parent: parent->dirItem
                                            flags: flags
                                     creationTime: convertTimespec(statBlock->st_birthtimespec)
                                 modificationTime: convertTimespec(statBlock->st_mtimespec)
                                       accessTime: convertTimespec(statBlock->st_atimespec)];

    // Explicitly check if the path is the System Data volume. We do not want to scan its contents
    // to prevent its contents from being scanned twice (as they also appear inside the root via
    // firmlinks). Ideally, we use a more generic mechanism for this, similar to how hardlinks are
    // handled, but there does not yet seem to be an API to support this.
    BOOL isDataVolume = (
                         [lastPathComponent isEqualToString: @"Data"] &&
                         [dirChildItem.path isEqualToString: @"/System/Volumes/Data"]
                        );

    // Only add directories that should be scanned (this does not necessarily mean that it has
    // passed the filter test already)
    if ( !isDataVolume && [treeGuide shouldDescendIntoDirectory: dirChildItem] ) {
      [parent->dirs addObject: dirChildItem];
      if (visitDescendants) {
        [self addToStack: dirChildItem entp: entp];
      }
    } else {
      NSLog(@"Skipping scan of %s", entp->fts_path);
      [progressTracker skippedFolder: dirChildItem];
      visitDescendants = NO;
    }

    [dirChildItem release];
  }
  else { // A file node.
    // TODO: Make blocksize a constant (is it always fixed?)
    ITEM_SIZE  physicalFileSize = statBlock->st_blocks * 512;
    ITEM_SIZE  fileSize;

    UniformType  *fileType =
      [typeInventory uniformTypeForExtension: lastPathComponent.pathExtension];

    switch (fileSizeMeasure) {
      case LogicalFileSize: {
        fileSize = [TreeBuilder getLogicalFileSize: entp withType: fileType];
        totalPhysicalSize += physicalFileSize;

        if (fileSize > physicalFileSize) {
          if (debugLogEnabled) {
            NSLog(@"Warning: logical file size larger than physical file size for %s (%llu > %llu)",
                  entp->fts_path, fileSize, physicalFileSize);
          }
          numOverestimatedFiles++;
        }
        break;
      }
      case PhysicalFileSize:
        fileSize = physicalFileSize;
        break;
      case TallyFileSize:
        fileSize = 1;
    }

    PlainFileItem  *fileChildItem = [[PlainFileItem allocWithZone: parent.zone]
                                     initWithLabel: lastPathComponent
                                            parent: parent->dirItem
                                              size: fileSize
                                              type: fileType
                                             flags: flags
                                      creationTime: convertTimespec(statBlock->st_birthtimespec)
                                  modificationTime: convertTimespec(statBlock->st_mtimespec)
                                        accessTime: convertTimespec(statBlock->st_atimespec)];

    // Only add file items that pass the filter test.
    if ( [treeGuide includeFileItem: fileChildItem] ) {
      [parent->files addObject: fileChildItem];
    }

    [fileChildItem release];
  }

  return visitDescendants;
}


/* Returns YES if item should be included in the tree. It returns NO when the item is hard-linked
 * and has already been encountered.
 */
- (BOOL) visitHardLinkedItem:(FTSENT *)entp {
  NSNumber  *fileNumber = [NSNumber numberWithUnsignedLongLong: entp->fts_statp->st_ino];
  NSUInteger  sizeBefore = hardLinkedFileNumbers.count;

  [hardLinkedFileNumbers addObject: fileNumber];

  return sizeBefore < hardLinkedFileNumbers.count; // Only scan newly encountered items
}

- (FTSENT *)startScan:(NSString *)path {
  char*  paths[2] = {(char *)path.UTF8String, NULL};
  ftsp = fts_open(paths, FTS_PHYSICAL | FTS_XDEV | FTS_NOCHDIR, NULL);

  if (ftsp == NULL) {
    NSLog(@"Error: fts_open failed for %@", path);
    return NULL;
  }

  // Get the root directory out of the way
  return fts_read(ftsp);
}

- (void) stopScan {
  fts_close(ftsp);
  ftsp = NULL;
}

- (int) determineNumSubFolders {
  int  numSubDirs = 0;
  FTSENT *entp = fts_children(ftsp, 0);
  while (entp != NULL) {
    if (S_ISDIR(entp->fts_statp->st_mode)) {
      numSubDirs++;
    }
    entp = entp->fts_link;
  }

  return numSubDirs;
}

@end // @implementation TreeBuilder (PrivateMethods)
