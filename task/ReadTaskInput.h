#import <Cocoa/Cocoa.h>


@interface ReadTaskInput : NSObject {
}

// Override designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithSourceUrl:(NSURL *)sourceUrl NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSURL *sourceUrl;

@end
