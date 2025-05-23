#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@class FileItemTest;

@interface FilterTestRepository : NSObject {
  // Contains the tests provided by the application.
  NSDictionary  *applicationProvidedTests;
}

@property (class, nonatomic, readonly) FilterTestRepository *defaultFilterTestRepository;

/* Returns the tests in a dictionary that can subsequently be modified.
 */
@property (nonatomic, readonly, strong) NotifyingDictionary *testsByNameAsNotifyingDictionary;

/* Returns dictionary as an NSDictionary, which is useful if the dictionary does not need to be
 * modified. Note, the dictionary can still be modified by casting it to NotifyingDictionary. This
 * is only a convenience method.
 */
@property (nonatomic, readonly, copy) NSDictionary *testsByName;

- (FileItemTest *)fileItemTestForName:(NSString *)name;

- (FileItemTest *)applicationProvidedTestForName:(NSString *)name;

- (void) storeUserCreatedTests;

@end
