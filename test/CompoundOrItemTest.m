#import "CompoundOrItemTest.h"

#import "FileItemTestVisitor.h"


@implementation CompoundOrItemTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"CompoundOrItemTest";
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  NSUInteger  max = self.subItemTests.count;
  NSUInteger  i = 0;
  BOOL  applicable = NO;
  
  while (i < max) {
    TestResult  result = [self.subItemTests[i++] testFileItem: item context: context];
      
    if (result == TestPassed) {
      // Short-circuit evaluation.
      return TestPassed;
    }
    if (result == TestFailed) {
      // Test cannot return "TestNotApplicable" anymore
      applicable = YES;
    }
  }

  return applicable ? TestFailed : TestNotApplicable;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitCompoundOrItemTest: self];
}


- (NSString *)bootstrapDescriptionTemplate {
  return NSLocalizedStringFromTable(@"(%@) or (%@)" , @"Tests",
                                    @"OR-test with 1: sub test, and 2: another sub test");
}

- (NSString *)repeatingDescriptionTemplate {
  return NSLocalizedStringFromTable(@"(%@) or %@" , @"Tests",
                                    @"OR-test with 1: sub test, and 2: two or more other sub tests");
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"CompoundOrItemTest"],
           @"Incorrect value for class in dictionary.");

  return [[[CompoundOrItemTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
