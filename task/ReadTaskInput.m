#import "ReadTaskInput.h"


@implementation ReadTaskInput

- (instancetype) initWithPath:(NSString *)path {
  if (self = [super init]) {
    _path = [path retain];
  }
  
  return self;
}

- (void) dealloc {
  [_path release];
  
  [super dealloc];
}

@end
