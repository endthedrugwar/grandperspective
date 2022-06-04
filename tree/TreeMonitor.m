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
    void *callbackInfo = self; // could put stream-specific data here.

    /* Create the stream, passing in a callback */
    eventStream = FSEventStreamCreate(NULL,
                                      &eventCallback,
                                      callbackInfo,
                                      pathsToWatch,
                                      kFSEventStreamEventIdSinceNow,
                                      EVENT_UPDATE_LATENCY,
                                      kFSEventStreamCreateFlagNone);

    FSEventStreamSetDispatchQueue(eventStream, dispatch_get_main_queue());
  }

  return self;
}

- (void) dealloc {
  FSEventStreamStop(eventStream);
  FSEventStreamInvalidate(eventStream);
  FSEventStreamRelease(eventStream);

  [super dealloc];
}

- (void) startMonitoring {
  FSEventStreamStart(eventStream);
}

@end // @implementation TreeMonitor

@implementation TreeMonitor (PrivateMethods)

- (void)invalidatePath:(NSString *)path mustScanSubDirs:(BOOL)mustScanSubDirs {
  ++_numChanges;

  FileItem *fileItem = [self.treeContext.scanTree fileItemForPath: path];
  if (fileItem != nil) {
    if (!fileItem.isDirectory) {
      fileItem = fileItem.parentDirectory;
    }

    ((DirectoryItem *)fileItem).rescanFlags |= (mustScanSubDirs
                                                ? DirectoryNeedsFullRescan
                                                : DirectoryNeedsShallowRescan);
  } else {
    NSLog(@"Warning: file item not found for %@", path);
    self.treeContext.scanTree.rescanFlags |= DirectoryNeedsFullRescan;
  }
}

@end // @implementation TreeMonitor (PrivateMethods)
