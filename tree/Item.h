#import <Cocoa/Cocoa.h>

typedef unsigned long long item_size_t;
typedef unsigned long long file_count_t;

@class FileItem;

@interface Item : NSObject {
}


- (instancetype) initWithItemSize:(item_size_t)size NS_DESIGNATED_INITIALIZER;

/* Applies the callback to all file item descendants.
 */
- (void) visitFileItemDescendants:(void(^)(FileItem *))callback;

/* Returns the first file item descendant matching the predicate.
 */
- (FileItem *)findFileItemDescendant:(BOOL(^)(FileItem *))predicate;

/* Item size should not be changed once it is set. It is not "readonly" to enable DirectoryItem
 * subclass to set it later (once it knows its size).
 */
@property (nonatomic) item_size_t itemSize;
@property (nonatomic, readonly) file_count_t numFiles;

// An item is virtual if it is not a file item (i.e. a file or directory).
@property (nonatomic, getter=isVirtual, readonly) BOOL virtual;

// TODO: Remove and use dedicated (package-aware) tree visitor instead.
@property (nonatomic, readonly) int maxDepth;

@end
