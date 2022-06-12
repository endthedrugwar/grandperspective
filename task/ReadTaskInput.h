#import <Cocoa/Cocoa.h>


@interface ReadTaskInput : NSObject {
}

// Override designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *path;

@end
