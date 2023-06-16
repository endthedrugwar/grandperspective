#import "TreeBuilder.h"

#include <fts.h>
#include <sys/stat.h>
#include <sys/mount.h>

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

  // (Unbalanced) trees containing the immediate children
  Item  *subdirs;
  Item  *files;
}

- (instancetype) init NS_DESIGNATED_INITIALIZER;

// Convenience "constructor" for repeated usage
- (void) initWithDirectoryItem:(DirectoryItem *)dirItem entp:(FTSENT *)entp;

- (void) addFile:(FileItem *)fileItem;
- (void) addSubdir:(FileItem *)dirItem;

@end // @interface ScanStackFrame


@interface TreeBuilder (PrivateMethods)

+ (ITEM_SIZE) getLogicalFileSize:(FTSENT *)entp withType:(UniformType *)fileType;

- (void) addToStack:(DirectoryItem *)dirItem entp:(FTSENT *)entp;
- (BOOL) unwindStackToParent:(FTSENT *)entp;

- (FileItem *)finalizeStackFrame:(ScanStackFrame *)stackFrame;

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
  if (self = [super init]) {
    dirItem = nil;
    subdirs = nil;
    files = nil;
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
  NSAssert(subdirs == nil && files == nil, @"Children not nil");
}

- (void) dealloc {
  [subdirs release];
  [files release];

  entp = NULL;
  [dirItem release];
  
  [super dealloc];
}

- (void) addFile:(FileItem *)fileItem {
  if (files == nil) {
    files = [fileItem retain];
  } else {
    CompoundItem  *newHead = [[CompoundItem alloc] initWithFirst: fileItem second: files];
    [files release];
    files = newHead;
  }
}

- (void) addSubdir:(FileItem *)dirItem {
  if (subdirs == nil) {
    subdirs = [dirItem retain];
  } else {
    CompoundItem  *newHead = [[CompoundItem alloc] initWithFirst: dirItem second: subdirs];
    [subdirs release];
    subdirs = newHead;
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

  NSString  *volumeFormat;
  [volumeRoot getResourceValue: &volumeFormat forKey: NSURLVolumeLocalizedFormatDescriptionKey
                         error: &error];
  if (error == nil) {
    NSLog(@"Volume format = %@", volumeFormat);
  }

  ignoreHardLinksForDirectories = NO; // Default
  struct statfs volinfo;
  if (statfs(volumeRoot.path.fileSystemRepresentation, &volinfo) == 0) {
    NSLog(@"fstypename = %s", volinfo.f_fstypename);
    if (strcmp("apfs", volinfo.f_fstypename) == 0) {
      // APFS does not support hardlinking directories. However, directories will have a non-zero
      // hardlink count, as each file it contains increases the count. So ignore this count when
      // deciding if a directory should be visited in APFS
      ignoreHardLinksForDirectories = YES;
    }
  }
  NSLog(@"ignoreHardLinksForDirectories = %d", ignoreHardLinksForDirectories);

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

  ScanTreeRoot  *scanTree = [ScanTreeRoot alloc];
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
          // Note: not popping from stack here, as this event can also occur without the item
          // being added to the stack (when the directory should be skipped)
          continue;
        case FTS_DNR:
        case FTS_ERR:
        case FTS_NS:
          if (debugLogEnabled) {
            NSLog(@"Error reading directory %s: %s", entp->fts_path, strerror(entp->fts_errno));
          }
          continue;
      }

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

    [self unwindStackToParent: nil];
    NSAssert(dirStackTopIndex == -1, @"Final stack unwind failed?");
  }
  @finally {
    [autoreleasePool release];
    [self stopScan];
  }

  return YES;
}

// TODO: Refactor and restore
//- (void) getContentsForDirectory:(DirectoryItem *)dirItem
//                          atPath:(NSString *)path
//                            dirs:(NSMutableArray<DirectoryItem *> *)dirs
//                           files:(NSMutableArray<PlainFileItem *> *)files {
//  ScanStackFrame  *parent = [[[ScanStackFrame alloc] initWithDirs: dirs files: files] autorelease];
//  [parent initWithDirectoryItem: dirItem entp: [self startScan: path]];
//
//  FTSENT *entp;
//  while ((entp = fts_read(ftsp)) != NULL) {
//    if (entp->fts_info == FTS_DP) continue; // Directory being visited a second time
//
//    BOOL  isDirectory = S_ISDIR(entp->fts_statp->st_mode);
//    [self visitItem: entp parent: parent recurse: NO];
//    if (isDirectory) {
//      fts_set(ftsp, entp, FTS_SKIP);
//    }
//  }
//
//  [self stopScan];
//}

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
  FileItem  *finalizedSubdir = nil;
  while (dirStackTopIndex >= 0) {
    ScanStackFrame  *topDir = dirStack[dirStackTopIndex];
    if (finalizedSubdir != nil) {
      [topDir addSubdir: finalizedSubdir];
    }
    if (topDir->entp == entp) {
      return YES;
    }

    finalizedSubdir = [self finalizeStackFrame: topDir];
    dirStackTopIndex--;
  }

  return NO;
}

- (FileItem *)finalizeStackFrame:(ScanStackFrame *)topDir {
//  NSLog(@"Pop: %s", topDir->entp->fts_path);

  DirectoryItem  *dirItem = topDir->dirItem;

  [dirItem setFileItems: [treeBalancer convertLinkedListToTree: topDir->files]
         directoryItems: [treeBalancer convertLinkedListToTree: topDir->subdirs]];

  [treeGuide emergedFromDirectory: dirItem];
  [progressTracker processedFolder: dirItem];

  return [treeGuide includeFileItem: dirItem] != nil ? dirItem : nil;
}

- (BOOL) visitItem:(FTSENT *)entp
            parent:(ScanStackFrame *)parent
           recurse:(BOOL)visitDescendants {
  FileItemOptions  flags = 0;
  struct stat  *statBlock = entp->fts_statp;
  BOOL  isDirectory = S_ISDIR(statBlock->st_mode);

  // Apple File System (APFS) does not support hard-links to directories, but has "hard links"
  // for each file a directory contains (including . and ..). So a possible optimization is to skip
  // the hardlink check for directories on APFS as this will greatly reduce the size of the set
  // used to track the hard-linked items. Note, some directories in /System/Volumes have the same
  // inode but their contents differ so there's no duplication in scanning each of these.
  if (statBlock->st_nlink > 1 && !(isDirectory && ignoreHardLinksForDirectories)) {
    flags |= FileItemIsHardlinked;

    if (![self visitHardLinkedItem: entp]) {
      // Do not visit descendants if the item was a directory
      if (isDirectory) {
        visitDescendants = NO;
      }

      return visitDescendants;
    }
  }

  NSString  *lastPathComponent = [NSString stringWithUTF8String: entp->fts_name];

  if (isDirectory) {
    // The package check is relatively expensive (amongst others because it requires an NSURL).
    // A possible optimization is to only apply it to directories with an extension, as most
    // packages are identified by extension. However, this fails to identify some packages.
    // On my macOS 12.6.3 on 2023/05 this applies to ~/Pictures/Photo Booth Library and
    // ~/Library/Application Support/SyncServices/Local.
    NSURL  *url = [NSURL fileURLWithFileSystemRepresentation: entp->fts_path
                                                 isDirectory: YES
                                               relativeToURL: NULL];
    if (url.isPackage) {
      flags |= FileItemIsPackage;
    }
    
    DirectoryItem  *dirChildItem = [[DirectoryItem alloc]
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

    // Check if directory should be scanned. It is only added as a sub-directory after scan is
    // completed, as it may be filtered.
    if ( !isDataVolume && [treeGuide shouldDescendIntoDirectory: dirChildItem] ) {
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
    // According to stat(2) documentation, st_blocks returns the number of 512B blocks allocated.
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

    PlainFileItem  *fileChildItem =
      [[PlainFileItem alloc] initWithLabel: lastPathComponent
                                    parent: parent->dirItem
                                      size: fileSize
                                      type: fileType
                                     flags: flags
                              creationTime: convertTimespec(statBlock->st_birthtimespec)
                          modificationTime: convertTimespec(statBlock->st_mtimespec)
                                accessTime: convertTimespec(statBlock->st_atimespec)];

    // Only add file items that pass the filter test.
    if ( [treeGuide includeFileItem: fileChildItem] ) {
      [parent addFile: fileChildItem];
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
  ftsp = fts_open(paths, FTS_PHYSICAL | FTS_XDEV, NULL);

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
