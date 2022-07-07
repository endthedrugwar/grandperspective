#import "TreeMonitor.h"

#import "DirectoryItem.h"
#import "TreeContext.h"

CFAbsoluteTime EVENT_UPDATE_LATENCY = 3.0; /* Latency in seconds */

@interface TreeMonitor (PrivateMethods)

- (void)invalidatePaths:(NSDictionary<NSString *, NSNumber *> *)paths;

- (void)invalidatePath:(NSString *)path mustScanSubDirs:(BOOL)mustScanSubDirs;

@end

void eventCallback(ConstFSEventStreamRef streamRef,
                   void *clientCallBackInfo,
                   size_t numEvents,
                   void *eventPaths,
                   const FSEventStreamEventFlags eventFlags[],
                   const FSEventStreamEventId eventIds[]) {
  char **paths = eventPaths;

  // Deleting a directory typically results in many duplicate events, one for each file inside the
  // directory. As finding the DirectoryItem for paths is relatively expensive, first collect all
  // the events in a dictionary to remove the duplicates.
  NSMutableDictionary<NSString*, NSNumber*>  *modifiedDirs =
    [NSMutableDictionary dictionaryWithCapacity: numEvents];

  for (int i = 0; i < numEvents; i++) {
    unsigned long eventFlag = eventFlags[i];
    NSString  *path = [NSString stringWithUTF8String: paths[i]];

    // printf("Change %llu in %s, flags %lu\n", eventIds[i], paths[i], eventFlag);

    if (eventFlag & kFSEventStreamEventFlagEventIdsWrapped) {
      NSLog(@"Warning: FSEvent IDs wrapped");
    }
    if ((eventFlag & kFSEventStreamEventFlagKernelDropped)
        || (eventFlag & kFSEventStreamEventFlagUserDropped)) {
      NSLog(@"Warning: Some FSEvents were dropped");
    }

    if (eventFlag & kFSEventStreamEventFlagMustScanSubDirs) {
      modifiedDirs[path] = [NSNumber numberWithBool: YES];
    }
    else if (modifiedDirs[path] == nil) {
      modifiedDirs[path] = [NSNumber numberWithBool: NO];
    }
  }

  TreeMonitor *treeMonitor = (TreeMonitor *)clientCallBackInfo;
  [treeMonitor invalidatePaths: modifiedDirs];
}

@implementation TreeMonitor

- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                             forPath:(NSString *)path {
  if (self = [super init]) {
    _treeContext = treeContext; // not retaining it, as it is not owned.
    _numChanges = 0;

    CFStringRef cf_path = (__bridge CFStringRef)path;
    CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&cf_path, 1, NULL);

    FSEventStreamContext context;
    context.info = (__bridge void *)self;
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;

    /* Create the stream, passing in a callback */
    eventStream = FSEventStreamCreate(NULL,
                                      &eventCallback,
                                      &context,
                                      pathsToWatch,
                                      kFSEventStreamEventIdSinceNow,
                                      EVENT_UPDATE_LATENCY,
                                      kFSEventStreamCreateFlagNone);

    FSEventStreamSetDispatchQueue(eventStream, dispatch_get_main_queue());

    rootPathComponents = [[[NSURL fileURLWithPath: path] pathComponents] retain];

    NSUserDefaults *args = NSUserDefaults.standardUserDefaults;
    debugLogEnabled = [args boolForKey: @"logAll"] || [args boolForKey: @"logMonitor"];
  }

  return self;
}

- (void) dealloc {
  NSLog(@"TreeMonitor dealloc");

  FSEventStreamStop(eventStream);
  FSEventStreamInvalidate(eventStream);
  FSEventStreamRelease(eventStream);

  [rootPathComponents release];

  [super dealloc];
}

- (void) startMonitoring {
  FSEventStreamStart(eventStream);
}

@end // @implementation TreeMonitor

@implementation TreeMonitor (PrivateMethods)

- (void)invalidatePaths:(NSDictionary<NSString *, NSNumber *> *)paths {
  [self.treeContext obtainWriteLock];

  for (id path in paths) {
    [self invalidatePath: path mustScanSubDirs: paths[path].boolValue];
  }

  [self.treeContext releaseWriteLock];
}

- (void)invalidatePath:(NSString *)path mustScanSubDirs:(BOOL)mustScanSubDirs {
  NSURL *url = [NSURL fileURLWithPath: path];
  NSArray<NSString *> *pathComponents = url.pathComponents;

  int i = 0;
  while (i < rootPathComponents.count) {
    if (![pathComponents[i] isEqualToString: rootPathComponents[i]]) {
      NSLog(@"Warning: Failed to match path %@ with root path", path);
      break;
    }
    ++i;
  }

  DirectoryRescanOptions flag = 0;
  DirectoryItem *dirItem = nil;

  if (i == rootPathComponents.count) {
    dirItem = self.treeContext.scanTree;
    while (i < pathComponents.count) {
      FileItem *child = [CompoundItem findFileItemChildMaybeNil: dirItem.directoryItems
                                                      predicate: ^(FileItem *file) {
        return [file.label isEqualToString: pathComponents[i]];
      }];
      if (child == nil) {
        // This typically happens when the user does not have permission to read the given
        // sub-directory, e.g. ~/Library/Cookies. It may also happen when the sub-directory was
        // created after the scan tree was created and subsequently modified.
        if (debugLogEnabled) {
          NSLog(@"Could not find sub-directory %@ in %@",
                pathComponents[i], dirItem.systemPath);
        }
        break;
      }
      else if (!child.isDirectory) {
        NSLog(@"Warning: Found file instead of directory for %@ in %@",
              pathComponents[i], dirItem.systemPath);
        break;
      }
      dirItem = (DirectoryItem *)child;
      ++i;
    }

    flag = mustScanSubDirs ? DirectoryNeedsFullRescan : DirectoryNeedsShallowRescan;
  } else {
    NSLog(@"Warning: Path not found %@. Invalidating entire tree", path);

    dirItem = self.treeContext.scanTree;
    flag = DirectoryNeedsFullRescan;
  }

  if ((dirItem.rescanFlags & flag) != flag) {
    dirItem.rescanFlags |= flag;

    ++_numChanges;
    NSLog(@"Updated rescanFlags for %@ to %d in response to event for %@",
          dirItem.path, dirItem.rescanFlags, path);
  }
}

@end // @implementation TreeMonitor (PrivateMethods)
