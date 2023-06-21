#import "CompoundAndItemTest.h"

#import "FileItemTestVisitor.h"


@implementation CompoundAndItemTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"CompoundAndItemTest";
}


- (TestResult) testFileItem:(FileItem *)item context:(id)context {
  NSInteger  max = self.subItemTests.count;
  NSInteger  i = 0;
  BOOL  applicable = NO;
  
  while (i < max) {
    TestResult  result = [self.subItemTests[i++] testFileItem: item context: context];
      
    if (result == TestFailed) {
      // Short-circuit evaluation
      return TestFailed;
    }
    if (result == TestPassed) {
      // Test cannot return "TestNotApplicable" anymore
      applicable = YES;
    }
  }

  return applicable ? TestPassed : TestNotApplicable;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitCompoundAndItemTest: self];
}


- (NSString *)bootstrapDescriptionTemplate {
  return NSLocalizedStringFromTable(@"(%@) and (%@)" , @"Tests",
                                    @"AND-test with 1: sub test, and 2: another sub test");
}

- (NSString *)repeatingDescriptionTemplate {
  return NSLocalizedStringFromTable(@"(%@) and %@" , @"Tests",
                                    @"AND-test with 1: sub test, and 2: two or more other sub tests");
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"CompoundAndItemTest"],
           @"Incorrect value for class in dictionary.");

  return [[[CompoundAndItemTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
