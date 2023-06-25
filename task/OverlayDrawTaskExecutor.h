#import "TaskExecutor.h"

NS_ASSUME_NONNULL_BEGIN

@class OverlayDrawer;
@class DirectoryItem;
@class TreeDrawerBaseSettings;

@interface OverlayDrawTaskExecutor : NSObject <TaskExecutor> {
  OverlayDrawer  *overlayDrawer;

  NSLock  *settingsLock;
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree;
- (instancetype) initWithScanTree:(DirectoryItem *)scanTree
                  drawingSettings:(TreeDrawerBaseSettings *)settings NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) TreeDrawerBaseSettings *overlayDrawerSettings;

@end

NS_ASSUME_NONNULL_END
