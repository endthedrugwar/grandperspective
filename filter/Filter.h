#import <Cocoa/Cocoa.h>


@class FilterTestRef;
@class FilterTestRepository;
@class FileItemTest;

/* A file item filter. It consists of one or more filter tests. The filter test
 * succeeds when any of its subtest succeed (i.e. the subtests are combined 
 * using the OR operator). Each filter subtest can optionally be inverted.
 *
 * The subtests are referenced by name, which means that the FileItemTest that
 * represents this filter is affected by any changes to used filter tests. The
 * current file item test can be obtained using
 * -createFileItemTestFromRepository:.
 */
@interface Filter : NSObject {
  // Array containing FilterTestRefs
  NSArray  *filterTests;
 }

+ (id) filter;
+ (id) filterWithFilterTests:(NSArray *)filterTests;
+ (id) filterWithFilter:(Filter *)filter;

/* Creates a filter from a dictionary as generated by -dictionaryForObject.
 */
+ (Filter *)filterFromDictionary:(NSDictionary *)dict;

/* Initialises an empty filter with an automatically generated name.
 */
- (id) init;

/* Initialises the filter with the given filter tests. The tests should be
 * instances of FilterTestRef.
 */
- (id) initWithFilterTests:(NSArray *)filterTests;

/* Initialises the filter based on the provided one. The newly created filter
 * will, however, not yet have an instantiated file item test. When the test is
 * (eventually) created using -createFileItemTestFromRepository:, it will be
 * based on the tests as then defined in the repository.
 */
- (id) initWithFilter:(Filter *)filter;

- (int) numFilterTests;
- (NSArray *)filterTests;
- (FilterTestRef *)filterTestAtIndex:(int) index;
- (FilterTestRef *)filterTestWithName:(NSString *)name;
- (int) indexOfFilterTest:(FilterTestRef *)test;


/* Creates and returns the test object that represents the filter given the
 * tests currently in the default test repository.
 *
 * If any test cannot be found in the repository its name will be added to
 * "unboundTests".
 */
- (FileItemTest *)createFileItemTestUnboundTests:(NSMutableArray *)unboundTests;

/* Creates and returns the test object that represents the filter given the
 * tests currently in the test repository.
 *
 * If any test cannot be found in the repository its name will be added to
 * "unboundTests".
 */
- (FileItemTest *)createFileItemTestFromRepository:(FilterTestRepository *)repository
                                      unboundTests:(NSMutableArray *)unboundTests;

/* Returns a dictionary that represents the object. It can be used for storing 
 * the object to preferences.
 */
- (NSDictionary *)dictionaryForObject;

@end // @interface Filter
