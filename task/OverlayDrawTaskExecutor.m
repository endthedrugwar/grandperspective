#import "OverlayDrawTaskExecutor.h"

#import "OverlayDrawer.h"
#import "OverlayDrawTaskInput.h"

@implementation OverlayDrawTaskExecutor

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree {
  if (self = [super init]) {
    overlayDrawer = [[OverlayDrawer alloc] initWithScanTree: scanTree];
  }
  return self;
}

- (void) dealloc {
  [overlayDrawer release];

  [super dealloc];
}

- (void) prepareToRunTask {
  [overlayDrawer clearAbortFlag];
}

- (id) runTaskWithInput:(id)input {
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
