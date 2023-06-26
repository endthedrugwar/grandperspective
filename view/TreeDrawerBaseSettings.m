#import "TreeDrawerBaseSettings.h"


const int MAX_DRAW_DEPTH_LIMIT = 8;
const int NO_DRAW_DEPTH_LIMIT = 0xFFFF;

@implementation TreeDrawerBaseSettings

// Creates default settings.
- (instancetype) init {
  return [self initWithMaxDepth: NO_DRAW_DEPTH_LIMIT
            showPackageContents: YES];
}

- (instancetype) initWithMaxDepth:(int)maxDepthVal
              showPackageContents:(BOOL)showPackageContentsVal {
  if (self = [super init]) {
    maxDepth = maxDepthVal;
    showPackageContents = showPackageContentsVal;
  }

  return self;
}


- (instancetype) settingsWithChangedMaxDepth:(int) maxDepthVal {
  return [[[TreeDrawerBaseSettings alloc] initWithMaxDepth: maxDepthVal
                                       showPackageContents: showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedShowPackageContents:(BOOL) showPackageContentsVal {
  return [[[TreeDrawerBaseSettings alloc] initWithMaxDepth: maxDepth
                                       showPackageContents: showPackageContentsVal] autorelease];
}

- (int) maxDepth {
  return maxDepth;
}

- (BOOL) showPackageContents {
  return showPackageContents;
}

@end
