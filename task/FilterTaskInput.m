#import "FilterTaskInput.h"

@implementation FilterTaskInput

- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                           filterSet:(FilterSet *)filterSet {
  if (self = [super init]) {
    _treeContext = [treeContext retain];
    _filterSet = [filterSet retain];
  }
  return self;
}

- (void) dealloc {
  [_treeContext release];
  [_filterSet release];
  
  [super dealloc];
}

@end
