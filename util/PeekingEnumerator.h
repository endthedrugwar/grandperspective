#import <Cocoa/Cocoa.h>


@interface PeekingEnumerator : NSObject {
  NSEnumerator  *enumerator;
  id  nextObject;
}

@property (nonatomic, readonly) id peekObject;

- (instancetype) initWithEnumerator:(NSEnumerator *)enumerator NS_DESIGNATED_INITIALIZER;

- (id) nextObject;

@end
