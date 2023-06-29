#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// The maximum depth limit, when a limit is applied
extern const unsigned MAX_DISPLAY_DEPTH_LIMIT;

// The depth limit value when there is no depth limiting
extern const unsigned NO_DISPLAY_DEPTH_LIMIT;

@interface TreeDrawerBaseSettings : NSObject {
}

// Creates default settings.
- (instancetype) init;

- (instancetype) initWithDisplayDepth:(unsigned)displayDepth
                  showPackageContents:(BOOL)showPackageContents NS_DESIGNATED_INITIALIZER;

- (instancetype) settingsWithChangedDisplayDepth:(unsigned)displayDepth;
- (instancetype) settingsWithChangedShowPackageContents:(BOOL)showPackageContents;

// The maximum depth that the drawer visits when drawing the tree. Directories at this depth are
// displayed a single blocks.
@property (nonatomic, readonly) unsigned displayDepth;

@property (nonatomic, readonly) BOOL showPackageContents;

@end

NS_ASSUME_NONNULL_END
