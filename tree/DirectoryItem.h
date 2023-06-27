#import <Cocoa/Cocoa.h>

#import "FileItem.h"


/* Bitmasks used for the "dirty" flags field of the DirectoryItem
 */
typedef NS_OPTIONS(UInt8, DirectoryRescanOptions) {
  DirectoryIsUpToDate = 0,
  DirectoryNeedsShallowRescan = 0x01,
  DirectoryNeedsFullRescan = 0x02,
};

@class PlainFileItem;
@class TreeBalancer;

@interface DirectoryItem : FileItem {
}

// Overrides designated initialiser
- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(item_size_t)size
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime NS_UNAVAILABLE;

/* A directory item is initialized without a size. It will be set when its contents are set using
 * setFileItems:directoryItems.
 */
- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime NS_DESIGNATED_INITIALIZER;

/* This method can be used to set the (balanced) trees for the file and sub-dirirectory children at
 * once.
 */
- (void) setFileItems:(Item *)fileItems
       directoryItems:(Item *)dirItems;

/* The addFile: and addSubDir: methods can be used to add file and sub-directory children one at a
 * time. Once done, the size should be locked using setSize, and the trees balanced using
 * balanceTree:
 */
- (void) addFile:(FileItem *)fileItem;
- (void) addSubdir:(FileItem *)dirItem;
- (void) setSize;
- (void) balanceTree:(TreeBalancer *)treeBalancer;

/* Replaces the directory contents. The item must have the same size as the original item (otherwise
 * the resulting tree would be incorrect).
 *
 * Note: It is the responsibility of the sender to ensure that this method is only called when the
 * tree can be modified (e.g. it should not be traversed in another thread). Furthermore, the sender
 * is responsible for notifying objects affected by the change.
 */
- (void) replaceFileItems:(Item *)newItem;
- (void) replaceDirectoryItems:(Item *)newItem;

/* The immediate children that are plain files. Depending on the number of file children it
 * returns:
 * 0 => nil
 * 1 => PlainFileItem
 * 2+ => a CompoundItem tree with PlainFileItem leaves
 */
@property (nonatomic, readonly, strong) Item *fileItems;

/* The immediate children that are directories. Depending on the number it returns:
 * 0 => nil
 * 1 => DirectoryItem
 * 2+ => a CompoundItem tree with DirectoryItem leaves
 */
@property (nonatomic, readonly, strong) Item *directoryItems;

/* Returns all immediate children, both plain file items as well as directories. This constructs
 * a temporary CompoundItem object when the directory contains both types of children.
 */
@property (nonatomic, readonly, strong) Item *childItems;

/* Return the directory represented as plain file.
 */
@property (nonatomic, readonly, strong) PlainFileItem *directoryAsPlainFile;

/* Returns the item that represents the receiver when package contents should not be shown (i.e.
 * when the directory should be represented by a file).
 */
@property (nonatomic, readonly, strong) FileItem *itemWhenHidingPackageContents;

/* Indicates if the state of the directory on disk has been changed since this object has been
 * created.
 *
 * This property is not immutable. It may be changed. However, it is the responsibility of the
 * sender to ensure that this method is only called when the tree can be modified (e.g. it should
 * not be traversed in another thread).
 */
@property (nonatomic) DirectoryRescanOptions rescanFlags;

/* Returns the maximum depth (the directory nesting level) of this part of the file tree. The
 * maximum level that is returned will not exceed upperBound. In other words, this parameter can be
 * used to restrict the search.
 */
- (int) maxDepth: (int)upperBound packagesAsFiles: (BOOL)packagesAsFiles;

@end
