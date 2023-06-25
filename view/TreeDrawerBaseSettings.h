#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern const int MAX_DRAW_DEPTH_LIMIT;

@interface TreeDrawerBaseSettings : NSObject {
  BOOL  showPackageContents;
  int  maxDepth;
}

// Creates default settings.
- (instancetype) init;

- (instancetype) initWithMaxDepth:(int)maxDepth
              showPackageContents:(BOOL)showPackageContents NS_DESIGNATED_INITIALIZER;

- (id) settingsWithChangedMaxDepth:(int)maxDepth;
- (id) settingsWithChangedShowPackageContents:(BOOL)showPackageContents;

// The maximum depth that the drawer visits when drawing the tree. Directories at this depth are
// displayed a single blocks.
@property (nonatomic, readonly) int maxDepth;

@property (nonatomic, readonly) BOOL showPackageContents;

@end

NS_ASSUME_NONNULL_END
