#import <Cocoa/Cocoa.h>

#import "FileItem.h"
#import "CompoundItem.h"


@interface DirectoryItem : FileItem {
}


/* A directory item is initialized without a size. It will be set when its contents are set using
 * setFileItems:directoryItems.
 */
- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime NS_DESIGNATED_INITIALIZER;

- (void) setFileItems:(Item *)fileItems
       directoryItems:(Item *)dirItems;

/* Replaces the directory contents. The item must have the same size as the original item (otherwise
 * the resulting tree would be incorrect).
 *
 * Note: It is the responsibility of the sender to ensure that this method is only called when the
 * tree can be modified (e.g. it should not be traversed in another thread). Furthermore, the sender
 * is responsible for notifying objects affected by the change.
 */
- (void) replaceFileItems:(Item *)newItem;
- (void) replaceDirectoryItems:(Item *)newItem;

/* The immediate children that are files. Depending on the number of file children it returns:
 * 0 => nil
 * 1 => FileItem
 * 2+ => a CompoundItem tree with FileItem leaves
 */
@property (nonatomic, readonly, strong) Item *fileItems;

/* The immediate children that are directories. Depending on the number it returns:
 * 0 => nil
 * 1 => DirectoryItem
 * 2+ => a CompoundItem tree with DirectoryItem leaves
 */
@property (nonatomic, readonly, strong) Item *directoryItems;

/* Returns the item that represents the receiver when package contents should not be shown (i.e.
 * when the directory should be represented by a file).
 */
@property (nonatomic, readonly, strong) FileItem *itemWhenHidingPackageContents;

@end
