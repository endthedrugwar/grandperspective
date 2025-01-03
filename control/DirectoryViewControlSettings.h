#import <Cocoa/Cocoa.h>

@class DirectoryViewDisplaySettings;

@interface DirectoryViewControlSettings : NSObject {
}

- (instancetype) initWithDisplaySettings:(DirectoryViewDisplaySettings *)displaySettings
                        unzoomedViewSize:(NSSize)viewSize
                            displayDepth:(unsigned)displayDepth NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) DirectoryViewDisplaySettings *displaySettings;

/* The window's size when it is unzoomed. This is considered its real size setting. When the
 * window is zoomed, the maximum size is only a temporary state.
 */
@property (nonatomic, readonly) NSSize unzoomedViewSize;

@property (nonatomic, readonly) unsigned displayDepth;

@end
