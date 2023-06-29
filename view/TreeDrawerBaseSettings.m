#import "TreeDrawerBaseSettings.h"


const int MAX_DISPLAY_DEPTH_LIMIT = 8;
const int NO_DISPLAY_DEPTH_LIMIT = 0xFFFF;

@implementation TreeDrawerBaseSettings

// Creates default settings.
- (instancetype) init {
  return [self initWithDisplayDepth: NO_DISPLAY_DEPTH_LIMIT
                showPackageContents: YES];
}

- (instancetype) initWithDisplayDepth:(int)displayDepth
                  showPackageContents:(BOOL)showPackageContents {
  if (self = [super init]) {
    _displayDepth = displayDepth;
    _showPackageContents = showPackageContents;
  }

  return self;
}


- (instancetype) settingsWithChangedDisplayDepth:(int) displayDepth {
  return [[[TreeDrawerBaseSettings alloc] initWithDisplayDepth: displayDepth
                                           showPackageContents: _showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedShowPackageContents:(BOOL) showPackageContents {
  return [[[TreeDrawerBaseSettings alloc] initWithDisplayDepth: _displayDepth
                                           showPackageContents: showPackageContents] autorelease];
}

@end
