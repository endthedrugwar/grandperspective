#import "AnnotatedTreeContext.h"

#import "TreeContext.h"

#import "FilterSet.h"
#import "FileItemTest.h"

@implementation AnnotatedTreeContext

+ (instancetype) annotatedTreeContext:(TreeContext *)treeContext {
  return (treeContext == nil 
          ? nil
          : [[[AnnotatedTreeContext alloc] initWithTreeContext: treeContext] autorelease]);
}

+ (instancetype) annotatedTreeContext:(TreeContext *)treeContext
                             comments:(NSString *)comments {
  return (treeContext == nil
          ? nil
          : [[[AnnotatedTreeContext alloc] initWithTreeContext: treeContext comments: comments]
             autorelease]);
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContext {
  FileItemTest  *test = treeContext.filterSet.fileItemTest;

  return [self initWithTreeContext: treeContext
                          comments: ((test != nil) ? test.description : @"")];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                            comments:(NSString *)comments {
  if (self = [super init]) {
    NSAssert(treeContext != nil, @"TreeContext must be set.");
  
    _treeContext = [treeContext retain];
    
    // Create a copy of the string, to ensure it is immutable.
    _comments = comments != nil ? [NSString stringWithString: comments] : @"";
    [_comments retain];
  }
  return self;
}

- (void) dealloc {
  [_treeContext release];
  [_comments release];

  [super dealloc];
}

@end
