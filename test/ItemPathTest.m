#import "ItemPathTest.h"

#import "DirectoryItem.h"
#import "StringTest.h"
#import "FileItemTestVisitor.h"
#import "FileItemPathStringCache.h"

@implementation ItemPathTest

- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"ItemPathTest";
}


- (TestResult) testFileItem:(FileItem *)item context:(id)context {
  NSString  *path = [context pathStringForFileItem: item];
  // Note: For performance reasons, the path string is not obtained from the item itself, but from
  // the context instead. The context, it is assumed, supports the pathStringForFileItem: method as
  // provided by the FileItemPathStringCache class. This way, path items do not constantly need to
  // be rebuilt from scratch, nor do they need to be maintained longer than needed.
  
  return [self.stringTest testString: path] ? TestPassed : TestFailed;
}

- (BOOL) appliesToDirectories {
  return YES;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemPathTest: self];
}


- (NSString *)description {
  NSString  *subject = NSLocalizedStringFromTable(@"path" , @"Tests",
                                                  @"A pathname as the subject of a string test");

  return [self.stringTest descriptionWithSubject: subject];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict {
  NSAssert([dict[@"class"] isEqualToString: @"ItemPathTest"],
           @"Incorrect value for class in dictionary.");

  return [[[ItemPathTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end
