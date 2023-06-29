#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// The maximum depth limit, when a limit is applied
extern const int MAX_DISPLAY_DEPTH_LIMIT;

// The depth limit value when there is no depth limiting
extern const int NO_DISPLAY_DEPTH_LIMIT;

@interface TreeDrawerBaseSettings : NSObject {
}

// Creates default settings.
- (instancetype) init;

- (instancetype) initWithDisplayDepth:(int)displayDepth
                  showPackageContents:(BOOL)showPackageContents NS_DESIGNATED_INITIALIZER;

- (instancetype) settingsWithChangedDisplayDepth:(int)displayDepth;
- (instancetype) settingsWithChangedShowPackageContents:(BOOL)showPackageContents;

// The maximum depth that the drawer visits when drawing the tree. Directories at this depth are
// displayed a single blocks.
@property (nonatomic, readonly) int displayDepth;

@property (nonatomic, readonly) BOOL showPackageContents;

@end

NS_ASSUME_NONNULL_END
