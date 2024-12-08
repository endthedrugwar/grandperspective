#import <Cocoa/Cocoa.h>


@class AnnotatedTreeContext;

@interface WriteTaskInput : NSObject {
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSURL *)path;
- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSURL *)path
                                      options:(id)options NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) AnnotatedTreeContext *annotatedTreeContext;
@property (nonatomic, readonly, strong) NSURL *path;
@property (nonatomic, readonly, strong) id options;

@end
