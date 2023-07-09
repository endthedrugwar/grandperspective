#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"


/* (Abstract) compound item test.
 */
@interface CompoundItemTest : FileItemTest  {
}

// Overrides designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithSubItemTests:(NSArray *)subTests NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSArray *subItemTests;

@end
