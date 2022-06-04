#import "TreeMonitor.h"


CFAbsoluteTime EVENT_UPDATE_LATENCY = 3.0; /* Latency in seconds */

void eventCallback(ConstFSEventStreamRef streamRef,
                   void *clientCallBackInfo,
                   size_t numEvents,
                   void *eventPaths,
                   const FSEventStreamEventFlags eventFlags[],
                   const FSEventStreamEventId eventIds[]) {
  char **paths = eventPaths;

  // printf("Callback called\n");
  for (int i = 0; i < numEvents; i++) {
    /* flags are unsigned long, IDs are uint64_t */
    printf("Change %llu in %s, flags %lu\n", eventIds[i], paths[i], (unsigned long)eventFlags[i]);
  }
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
