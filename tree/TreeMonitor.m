#import "TreeMonitor.h"

#import "DirectoryItem.h"
#import "TreeContext.h"

CFAbsoluteTime EVENT_UPDATE_LATENCY = 3.0; /* Latency in seconds */

@interface TreeMonitor (PrivateMethods)

- (void)invalidatePath:(NSString *)path mustScanSubDirs:(BOOL)mustScanSubDirs;

@end

void eventCallback(ConstFSEventStreamRef streamRef,
                   void *clientCallBackInfo,
                   size_t numEvents,
                   void *eventPaths,
                   const FSEventStreamEventFlags eventFlags[],
                   const FSEventStreamEventId eventIds[]) {
  char **paths = eventPaths;
  TreeMonitor *treeMonitor = (TreeMonitor *)clientCallBackInfo;

  [treeMonitor.treeContext obtainWriteLock];

  for (int i = 0; i < numEvents; i++) {
    unsigned long eventFlag = eventFlags[i];
    char *path = paths[i];

    printf("Change %llu in %s, flags %lu\n", eventIds[i], path, eventFlag);

    if (eventFlag & kFSEventStreamEventFlagEventIdsWrapped) {
      NSLog(@"Warning: FSEvent IDs wrapped");
    }
    if ((eventFlag & kFSEventStreamEventFlagKernelDropped)
        || (eventFlag & kFSEventStreamEventFlagUserDropped)) {
      NSLog(@"Warning: Some FSEvents were dropped");
    }
    [treeMonitor invalidatePath: [NSString stringWithUTF8String: paths[i]]
                mustScanSubDirs: (eventFlag & kFSEventStreamEventFlagMustScanSubDirs)];
  }

  [treeMonitor.treeContext releaseWriteLock];
}

@implementation TreeMonitor

- (instancetype) init {
  NSAssert(NO, @"Use initWithTreeContext: instead");
  return [self initWithTreeContext: nil forPath: @""];
}

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

- (void)invalidatePath:(NSString *)path mustScanSubDirs:(BOOL)mustScanSubDirs {
  ++_numChanges;

  NSURL *url = [NSURL fileURLWithPath: path];
  NSArray<NSString *> *pathComponents = url.pathComponents;

  int i = 0;
  while (i < rootPathComponents.count) {
    if (![pathComponents[i] isEqualToString: rootPathComponents[i]]) {
      NSLog(@"Failed to match path %@ with root path", path);
      break;
    }
    ++i;
  }

  if (i == rootPathComponents.count) {
    DirectoryItem *dirItem = self.treeContext.scanTree;
    while (i < pathComponents.count) {
      DirectoryItem *child = [dirItem getSubDirectoryWithLabel: pathComponents[i]];
      if (child == nil) {
        // This can happen when the sub-directory was created after the scan tree was created and
        // subsequently modified.
        NSLog(@"Could not find sub-directory %@ in %@", pathComponents[i], dirItem.systemPath);
        break;
      }
      dirItem = child;
      ++i;
    }

    dirItem.rescanFlags |= (mustScanSubDirs
                            ? DirectoryNeedsFullRescan
                            : DirectoryNeedsShallowRescan);

    NSLog(@"Updated rescanFlags for %@", dirItem.path);
  } else {
    NSLog(@"Warning: file item not found for %@", path);
    self.treeContext.scanTree.rescanFlags |= DirectoryNeedsFullRescan;
  }
}

@end // @implementation TreeMonitor (PrivateMethods)
