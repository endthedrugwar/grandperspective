#import <Cocoa/Cocoa.h>

@class FilterSet;
@class DirectoryItem;


@interface ScanTaskInput : NSObject {
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)measure
                    filterSet:(FilterSet *)filterSet;

- (instancetype) initWithTreeSource:(DirectoryItem *)treeSource
                    fileSizeMeasure:(NSString *)measure
                          filterSet:(FilterSet *)filterSet;

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)measure
                    filterSet:(FilterSet *)filterSet
                   treeSource:(DirectoryItem *)treeSource NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly, copy) NSString *fileSizeMeasure;
@property (nonatomic, readonly, strong) FilterSet *filterSet;

// Optional: When not nil, the scan should use this as source and only scan/refresh the outdated
// directories, as indicated by their rescanFlags.
@property (nonatomic, readonly, strong) DirectoryItem *treeSource;

@end
