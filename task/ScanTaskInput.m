#import "ScanTaskInput.h"

#import "PreferencesPanelControl.h"
#import "DirectoryItem.h"


@implementation ScanTaskInput

- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)fileSizeMeasureVal
                    filterSet:(FilterSet *)filterSetVal {
  BOOL  showPackageContentsByDefault =
    [NSUserDefaults.standardUserDefaults boolForKey: ShowPackageContentsByDefaultKey];
            
  return [self initWithPath: path
            fileSizeMeasure: fileSizeMeasureVal
                  filterSet: filterSetVal
            packagesAsFiles: !showPackageContentsByDefault
                 treeSource: nil];
}

- (instancetype) initWithTreeSource:(DirectoryItem *)treeSource
                    fileSizeMeasure:(NSString *)measure
                          filterSet:(FilterSet *)filterSet
                    packagesAsFiles:(BOOL) packagesAsFiles {
  return [self initWithPath: treeSource.systemPath
            fileSizeMeasure: measure
                  filterSet: filterSet
            packagesAsFiles: packagesAsFiles
                 treeSource: treeSource];
}
         
- (instancetype) initWithPath:(NSString *)path
              fileSizeMeasure:(NSString *)fileSizeMeasure
                    filterSet:(FilterSet *)filterSet
              packagesAsFiles:(BOOL) packagesAsFiles
                   treeSource:(DirectoryItem *)treeSource {
  if (self = [super init]) {
    _path = [path retain];
    _fileSizeMeasure = [fileSizeMeasure retain];
    _filterSet = [filterSet retain];
    _packagesAsFiles = packagesAsFiles;
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
