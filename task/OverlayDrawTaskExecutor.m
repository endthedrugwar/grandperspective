#import "OverlayDrawTaskExecutor.h"

#import "OverlayDrawer.h"
#import "OverlayDrawTaskInput.h"
#import "TreeDrawerBaseSettings.h"

@implementation OverlayDrawTaskExecutor

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree {
  return [self initWithScanTree: scanTree
                 drawingSettings: [[[TreeDrawerBaseSettings alloc] init] autorelease]];
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree
                  drawingSettings:(TreeDrawerBaseSettings *)settings {
  if (self = [super init]) {
    overlayDrawer = [[OverlayDrawer alloc] initWithScanTree: scanTree];
    _overlayDrawerSettings = [settings retain];

    settingsLock = [[NSLock alloc] init];
  }
  return self;
}

- (void) dealloc {
  [overlayDrawer release];
  [_overlayDrawerSettings release];
  [settingsLock release];

  [super dealloc];
}


- (void) setOverlayDrawerSettings:(TreeDrawerBaseSettings *)settings {
  [settingsLock lock];
  if (settings != _overlayDrawerSettings) {
    [_overlayDrawerSettings release];
    _overlayDrawerSettings = [settings retain];
  }
  [settingsLock unlock];
}


- (void) prepareToRunTask {
  [overlayDrawer clearAbortFlag];
}

- (id) runTaskWithInput:(id)input {
  [settingsLock lock];
  // Even though the settings are immutable, obtaining the settingsLock
  // ensures that it is not de-allocated while it is being used.
  [overlayDrawer updateSettings: self.overlayDrawerSettings];
  [settingsLock unlock];

  OverlayDrawTaskInput  *overlayInput = input;

  return [overlayDrawer drawOverlayImageOfVisibleTree: overlayInput.visibleTree
                                       startingAtTree: overlayInput.treeInView
                                   usingLayoutBuilder: overlayInput.layoutBuilder
                                               inRect: overlayInput.bounds
                                          overlayTest: overlayInput.overlayTest];
}

- (void) abortTask {
  [overlayDrawer abortDrawing];
}

@end
