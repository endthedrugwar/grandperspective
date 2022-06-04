#import <Cocoa/Cocoa.h>

@class TreeContext;

@interface TreeMonitor : NSObject {
@private
  // Cannot synthesize weak properties apparently
  __weak TreeContext *_treeContext;

  FSEventStreamRef eventStream;

  NSArray<NSString *> *rootPathComponents;
}

@property (nonatomic, readonly, weak) TreeContext *treeContext;
@property (nonatomic, readonly) int numChanges;

- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                             forPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

- (void) startMonitoring;

@end
