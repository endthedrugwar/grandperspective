#import "ItemNameTest.h"

#import "FileItem.h"
#import "StringTest.h"
#import "FileItemTestVisitor.h"


@implementation ItemNameTest 

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"ItemNameTest";
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  return [self.stringTest testString: [item pathComponent]] ? TestPassed : TestFailed;
}

- (BOOL) appliesToDirectories {
  return YES;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemNameTest: self];
}


- (NSString *)description {
  NSString  *subject = 
    NSLocalizedStringFromTable(@"name" , @"Tests",
                               @"A filename as the subject of a string test");

  return [self.stringTest descriptionWithSubject: subject];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"ItemNameTest"],
           @"Incorrect value for class in dictionary.");

  return [[[ItemNameTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
