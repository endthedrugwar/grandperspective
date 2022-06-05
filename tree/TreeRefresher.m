#import "TreeRefresher.h"


@interface TreeRefresher (PrivateMethods)

@end // @interface TreeRefresher (PrivateMethods)


@implementation TreeRefresher

- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal {
  NSAssert(NO, @"Use initWithFilterSet:oldTree: instead");
  return [self initWithFilterSet: nil oldTree: nil];
}

- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal
                           oldTree:(DirectoryItem *)oldTreeVal {
  if (self = [super initWithFilterSet: filterSetVal]) {
    oldTree = [oldTreeVal retain];
  }
  return self;
}

- (void) dealloc {
  [oldTree release];

  [super dealloc];
}

@end // @implementation TreeRefresher

@implementation TreeRefresher (ProtectedMethods)

/* Constructs a tree for the given folder. It is used to implement buildTreeForPath:
 *
 * Overrides method in parent class to provide refresh implementation.
 */
- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path {
  // TODO: Implement with refresh logic

  return NO;
}

@end // @implementation TreeRefresher (ProtectedMethods)

@implementation TreeRefresher (PrivateMethods)

@end // @implementation TreeRefresher (PrivateMethods)
