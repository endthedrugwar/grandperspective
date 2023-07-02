#import "DirectoryViewControlSettings.h"

#import "DirectoryViewDisplaySettings.h"
#import "PreferencesPanelControl.h"
#import "TreeDrawerBaseSettings.h"

@implementation DirectoryViewControlSettings

- (instancetype) init {
  NSUserDefaults  *ud = NSUserDefaults.standardUserDefaults;

  return [self initWithDisplaySettings: [DirectoryViewDisplaySettings defaultSettings]
                      unzoomedViewSize: NSMakeSize([ud floatForKey: DefaultViewWindowWidth],
                                                   [ud floatForKey: DefaultViewWindowHeight])
                          displayDepth: TreeDrawerBaseSettings.defaultDisplayDepth];
}

- (instancetype) initWithDisplaySettings:(DirectoryViewDisplaySettings *)displaySettings
                        unzoomedViewSize:(NSSize)unzoomedViewSize
                            displayDepth:(unsigned)displayDepth {
  if (self = [super init]) {
    _displaySettings = [displaySettings retain];
    _unzoomedViewSize = unzoomedViewSize;
    _displayDepth = displayDepth;
  }
  
  return self;
}

- (void) dealloc {
  [_displaySettings release];

  [super dealloc];
}

@end
