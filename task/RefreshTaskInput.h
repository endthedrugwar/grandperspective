#import <Cocoa/Cocoa.h>

@class DirectoryItem;
@class FilterSet;

@interface RefreshTaskInput : NSObject {
}

- (instancetype) initWithTreeSource:(DirectoryItem *)treeSource
                    fileSizeMeasure:(NSString *)measure
                          filterSet:(FilterSet *)filterSet;

- (instancetype) initWithTreeSource:(DirectoryItem *)treeSource
                    fileSizeMeasure:(NSString *)measure
                          filterSet:(FilterSet *)filterSet
                    packagesAsFiles:(BOOL) packagesAsFiles NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) DirectoryItem *treeSource;
@property (nonatomic, readonly, copy) NSString *fileSizeMeasure;
@property (nonatomic, readonly, strong) FilterSet *filterSet;
@property (nonatomic, readonly) BOOL packagesAsFiles;

@end
