#import "ItemStringTest.h"

#import "StringTest.h"


@implementation ItemStringTest

- (instancetype) initWithStringTest:(StringTest *)stringTestVal {
  if (self = [super init]) {
    _stringTest = [stringTestVal retain];
  }
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSDictionary  *stringTestDict = dict[@"stringTest"];
    
    _stringTest = [[StringTest stringTestFromDictionary: stringTestDict] retain];
  }
  
  return self;
}

- (void) dealloc {
  [_stringTest release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"stringTest"] = [self.stringTest dictionaryForObject];
}


- (TestResult) testFileItem:(FileItem *)item {
  NSAssert(NO, @"This method must be overridden.");
  return TEST_FAILED;
}

@end
