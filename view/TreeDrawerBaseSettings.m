#import "TreeDrawerBaseSettings.h"


const int MAX_DRAW_DEPTH_LIMIT = 0xFFFF;

@implementation TreeDrawerBaseSettings

// Creates default settings.
- (instancetype) init {
  return [self initWithMaxDepth: MAX_DRAW_DEPTH_LIMIT
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


- (id) settingsWithChangedMaxDepth:(int) maxDepthVal {
  return [[[TreeDrawerBaseSettings alloc] initWithMaxDepth: maxDepthVal
                                       showPackageContents: showPackageContents] autorelease];
}

- (id) settingsWithChangedShowPackageContents:(BOOL) showPackageContentsVal {
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
