#import <Cocoa/Cocoa.h>

#import "FileItemTest.h"
#import "Item.h"

/**
 * Item size test.
 */
@interface ItemSizeTest : FileItemTest  {
}

// Overrides designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithLowerBound:(item_size_t)lowerBound;

- (instancetype) initWithUpperBound:(item_size_t)upperBound;

- (instancetype) initWithLowerBound:(item_size_t)lowerBound
                         upperBound:(item_size_t)upperBound NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) BOOL hasLowerBound;
@property (nonatomic, readonly) BOOL hasUpperBound;

@property (nonatomic, readonly) unsigned long long lowerBound;
@property (nonatomic, readonly) unsigned long long upperBound;

+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict;

@end
