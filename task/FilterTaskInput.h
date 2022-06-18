#import <Cocoa/Cocoa.h>

@class TreeContext;
@class FilterSet;


@interface FilterTaskInput : NSObject {
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithTreeContext:(TreeContext *)context
                           filterSet:(FilterSet *)filterSet NS_DESIGNATED_INITIALIZER;


@property (nonatomic, readonly, strong) TreeContext *treeContext;
@property (nonatomic, readonly, strong) FilterSet *filterSet;

@end
