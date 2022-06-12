#import "WriteTaskInput.h"


@implementation WriteTaskInput

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path {
  return [self initWithAnnotatedTreeContext: context path: path options: nil];
}

- (instancetype) initWithAnnotatedTreeContext:(AnnotatedTreeContext *)context
                                         path:(NSString *)path
                                      options:(id)options {
  if (self = [super init]) {
    _annotatedTreeContext = [context retain];
    _path = [path retain];
    _options = [options retain];
  }
  
  return self;
}

- (void) dealloc {
  [_annotatedTreeContext release];
  [_path release];
  [_options release];
  
  [super dealloc];
}

@end
