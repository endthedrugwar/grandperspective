#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"

@class StringTest;

/* (Abstract) item string-based test.
 */
@interface ItemStringTest : FileItemTest  {
}

// Overrides designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithStringTest:(StringTest *)stringTest NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) StringTest *stringTest;

@end
