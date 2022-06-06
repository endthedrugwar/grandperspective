#import <Cocoa/Cocoa.h>

#import "Item.h"

@class FileItem;

NS_ASSUME_NONNULL_BEGIN

@interface CompoundItem : Item {
  FILE_COUNT  numFiles;
}

- (instancetype) initWithItemSize:(ITEM_SIZE)size NS_UNAVAILABLE;

/* Both items must be non-nil.
 */
- (instancetype) initWithFirst:(Item *)first
                        second:(Item *)second NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) Item *first;

@property (nonatomic, readonly, strong) Item *second;

/* Replaces the first item. The item must have the same size as the original one (otherwise the
 * resulting tree would be incorrect).
 *
 * Note: It is the responsibility of the sender to ensure that this method is only called when the
 * tree can be modified (e.g. it should not be traversed in another thread). Furthermore, the sender
 * is responsible for notifying objects affected by the change.
 */
- (void) replaceFirst:(Item *)newItem;

// Replaces the second item. See also -replaceFirst.
- (void) replaceSecond:(Item *)newItem;

- (FileItem *)findFileItemWithLabel:(NSString *)label;

/* Can handle case where either one or both are nil. If both are nil, it returns nil. If one item is
 * nil, it returns the other item. Otherwise it returns a CompoundItem containing both.
 */
+ (Item *)compoundItemWithFirst:(nullable Item *)first second:(nullable Item *)second;

/* Visits all FileItem leave nodes in the tree with "item" at the root and applies the callback on
 * each.
 *
 * It handles the case where item is a CompoundItem (the typical case), but also accepts single
 * item trees where the root is a FileItem.
 *
 * Note: It does not recurse into DirectoryItem nodes.
 */
+ (void)visitLeaves:(Item *)item callback:(void(^)(FileItem *))callback;

/* Sames as visitLeaves but item may be nil.
 */
+ (void)visitLeavesMaybeNil:(nullable Item *)item callback:(void(^)(FileItem *))callback;

@end

NS_ASSUME_NONNULL_END
