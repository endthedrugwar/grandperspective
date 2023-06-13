#import <Cocoa/Cocoa.h>

#define ITEM_SIZE  unsigned long long
#define FILE_COUNT  unsigned long long

@class FileItem;

@interface Item : NSObject {
}


- (instancetype) initWithItemSize:(ITEM_SIZE)size NS_DESIGNATED_INITIALIZER;

/* Applies the callback to all file item descendants.
 */
- (void) visitFileItemDescendants:(void(^)(FileItem *))callback;

/* Returns the first file item descendant matching the predicate.
 */
- (FileItem *)findFileItemDescendant:(BOOL(^)(FileItem *))predicate;

/* Item size should not be changed once it is set. It is not "readonly" to enable DirectoryItem
 * subclass to set it later (once it knows its size).
 */
@property (nonatomic) ITEM_SIZE itemSize;
@property (nonatomic, readonly) FILE_COUNT numFiles;

// An item is virtual if it is not a file item (i.e. a file or directory).
@property (nonatomic, getter=isVirtual, readonly) BOOL virtual;

@end
