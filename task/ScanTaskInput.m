#import "ScanTaskInput.h"

#import "PreferencesPanelControl.h"
#import "DirectoryItem.h"


@implementation ScanTaskInput

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)fileSizeMeasureVal
                    filterSet:(FilterSet *)filterSetVal {
  return [self initWithPath: path
            fileSizeMeasure: fileSizeMeasureVal
                  filterSet: filterSetVal
                 treeSource: nil];
}

- (instancetype) initWithTreeSource:(DirectoryItem *)treeSource
                    fileSizeMeasure:(NSString *)measure
                          filterSet:(FilterSet *)filterSet {
  return [self initWithPath: treeSource.systemPath
            fileSizeMeasure: measure
                  filterSet: filterSet
                 treeSource: treeSource];
}
         
- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)fileSizeMeasure
                    filterSet:(FilterSet *)filterSet
                   treeSource:(DirectoryItem *)treeSource {
  if (self = [super init]) {
    _path = [path retain];
    _fileSizeMeasure = [fileSizeMeasure retain];
    _filterSet = [filterSet retain];
    _treeSource = [treeSource retain];
  }
  return self;
}

- (void) dealloc {
  [_path release];
  [_fileSizeMeasure release];
  [_filterSet release];
  [_treeSource release];
  
  [super dealloc];
}

@end
