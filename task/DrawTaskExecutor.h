#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class DirectoryItem;
@class TreeDrawer;
@class TreeDrawerSettings;
@class TreeContext;


@interface DrawTaskExecutor : NSObject <TaskExecutor> {
  TreeContext  *treeContext;

  TreeDrawer  *treeDrawer;

  NSLock  *settingsLock;
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithTreeContext:(TreeContext *)treeContext;
- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                     drawingSettings:(TreeDrawerSettings *)settings NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) TreeDrawerSettings *treeDrawerSettings;

@end
