#import "StatefulFileItemMapping.h"


@implementation StatefulFileItemMapping

- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)scheme {
  if (self = [super init]) {
    _scheme = [scheme retain];
  } 
  
  return self;
}

- (void) dealloc {
  [_scheme release];

  [super dealloc];
}


- (NSObject <FileItemMappingScheme> *)fileItemMappingScheme {
  return _scheme;
}


- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  return 0;
}

- (NSUInteger) hashForFileItem:(FileItem *)item inTree:(FileItem *)treeRoot {
  // By default assuming that "depth" is not used in the hash calculation.
  // If it is, this method needs to be overridden.
  return [self hashForFileItem: item atDepth: 0];
}


- (BOOL) canProvideLegend {
  return NO;
}

@end
