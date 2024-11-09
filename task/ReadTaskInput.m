#import "ReadTaskInput.h"


@implementation ReadTaskInput

- (instancetype) initWithSourceUrl:(NSURL *)sourceUrl {
  if (self = [super init]) {
    _sourceUrl = [sourceUrl retain];
  }
  
  return self;
}

- (void) dealloc {
  [_sourceUrl release];
  
  [super dealloc];
}

@end
