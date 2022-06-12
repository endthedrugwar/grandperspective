#import "DrawTaskInput.h"

NS_ASSUME_NONNULL_BEGIN

@class FileItemTest;

@interface OverlayDrawTaskInput : DrawTaskInput

// Override designated initializer of super.
- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds NS_UNAVAILABLE;

- (instancetype) initWithVisibleTree:(FileItem *)visibleTree
                          treeInView:(FileItem *)treeInView
                       layoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                              bounds:(NSRect) bounds
                         overlayTest:(FileItemTest *)overlayTest NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) FileItemTest *overlayTest;

@end

NS_ASSUME_NONNULL_END
