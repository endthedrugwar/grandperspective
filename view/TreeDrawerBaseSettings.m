#import "TreeDrawerBaseSettings.h"

#import "PreferencesPanelControl.h"

const unsigned MIN_DISPLAY_DEPTH_LIMIT = 1;
const unsigned MAX_DISPLAY_DEPTH_LIMIT = 8;
const unsigned NO_DISPLAY_DEPTH_LIMIT = 0xFFFF;

@implementation TreeDrawerBaseSettings

// Creates default settings.
- (instancetype) init {
  return [self initWithDisplayDepth: TreeDrawerBaseSettings.defaultDisplayDepth
                showPackageContents: TreeDrawerBaseSettings.showPackageContentsByDefault];
}

- (instancetype) initWithDisplayDepth:(unsigned)displayDepth
                  showPackageContents:(BOOL)showPackageContents {
  if (self = [super init]) {
    _displayDepth = displayDepth;
    _showPackageContents = showPackageContents;
  }

  return self;
}


- (instancetype) settingsWithChangedDisplayDepth:(unsigned) displayDepth {
  return [[[TreeDrawerBaseSettings alloc] initWithDisplayDepth: displayDepth
                                           showPackageContents: _showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedShowPackageContents:(BOOL) showPackageContents {
  return [[[TreeDrawerBaseSettings alloc] initWithDisplayDepth: _displayDepth
                                           showPackageContents: showPackageContents] autorelease];
}

+ (BOOL) showPackageContentsByDefault {
  return [NSUserDefaults.standardUserDefaults boolForKey: ShowPackageContentsByDefaultKey];
}

+ (unsigned) defaultDisplayDepth {
  NSString  *value = [NSUserDefaults.standardUserDefaults stringForKey: DefaultDisplayFocusKey];

  if ([value isEqualToString: UnlimitedDisplayFocusValue]) {
    return NO_DISPLAY_DEPTH_LIMIT;
  }

  int  depth = [value intValue];

  // Ensure the setting has a valid value (to avoid crashes/strange behavior should the user
  // manually change the preference)
  return (depth > MAX_DISPLAY_DEPTH_LIMIT
          ? NO_DISPLAY_DEPTH_LIMIT
          : (unsigned)MAX(depth, MIN_DISPLAY_DEPTH_LIMIT));
}

@end
