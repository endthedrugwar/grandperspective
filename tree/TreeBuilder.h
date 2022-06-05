#import <Cocoa/Cocoa.h>

#import "FileItem.h"

extern NSString  *LogicalFileSizeName;
extern NSString  *PhysicalFileSizeName;
extern NSString  *TallyFileSizeName;

typedef NS_ENUM(NSInteger, FileSizeEnum) {
  LogicalFileSize = 1,
  PhysicalFileSize = 2,
  TallyFileSize = 3
};

@class AlertMessage;
@class FilteredTreeGuide;
@class TreeBalancer;
@class UniformTypeInventory;
@class FileItem;
@class PlainFileItem;
@class DirectoryItem;
@class FilterSet;
@class TreeContext;
@class ScanProgressTracker;


/* Constructs trees for folders by (recursively) scanning the folder's contents.
 */
@interface TreeBuilder : NSObject {
  FilterSet  *filterSet;

  NSString  *fileSizeMeasureName;
  FileSizeEnum  fileSizeMeasure;

  NSArray<NSURLResourceKey>  *dirEnumKeysFullScan;
  NSArray<NSURLResourceKey>  *dirEnumKeysCountSubdirs;

  // In case logical file sizes are used, tracks total physical size.
  ITEM_SIZE  totalPhysicalSize;
  // In case logical file sizes are used, tracks how many files are actually smaller than reported.
  int  numOverestimatedFiles;

  BOOL  abort;
  FilteredTreeGuide  *treeGuide;
  TreeBalancer  *treeBalancer;
  UniformTypeInventory  *typeInventory;
  
  // Contains the file numbers of the hard linked files that have been encountered so far. If a file
  // with a same number is encountered once more, it is ignored.
  NSMutableSet  *hardLinkedFileNumbers;
  
  ScanProgressTracker  *progressTracker;
  
  NSMutableArray  *dirStack;
  // The index of the top element on the stack. It is not necessarly the last object in the array,
  // as items on the stack are never popped but kept for re-use.
  int  dirStackTopIndex;
  
  BOOL  debugLogEnabled;
}

+ (NSArray *)fileSizeMeasureNames;

- (instancetype) init;
- (instancetype) initWithFilterSet:(FilterSet *)filterSet NS_DESIGNATED_INITIALIZER;

@property (nonatomic) BOOL packagesAsFiles;

@property (nonatomic, copy) NSString *fileSizeMeasure;

/* Construct a full tree for the given folder.
 */
- (TreeContext *)buildTreeForPath:(NSString *)path;

/* Constructs a partial tree for the given folder.
 *
 * It is used to implement buildTreeForPath: but also by TreeRefresher to refresh parts of a tree.
 */
- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path;

/* Performs a shallow scan of the folder at the given path to determine its contents.
 *
 * Note: The dirItem is provided so that it can be used as a parent for its children. However, it
 * is not updated as the scan is shallow. Before the directory can be finalized, its
 * sub-directory children need to be populated first.
 */
- (BOOL) getContentsForDirectory:(DirectoryItem *)dirItem
                          atPath:(NSString *)path
                            dirs:(NSMutableArray<DirectoryItem *> *)dirs
                           files:(NSMutableArray<PlainFileItem *> *)files;

- (void) abort;

/* Returns a dictionary containing information about the progress of the ongoing tree-building task.
 *
 * It can safely be invoked from a different thread than the one that invoked -buildTreeForPath:
 * (and not doing so would actually be quite silly).
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

/* An alert in case a warning should be shown to the user regarding the scan results.
 *
 * Note: This class does not directly create an instance of an NSAlert. That should always be done
 * on the main thread to avoid exceptions.
 */
@property (nonatomic, readonly, strong) AlertMessage *alertMessage;

@end
