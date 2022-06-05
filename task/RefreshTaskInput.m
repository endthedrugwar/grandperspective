#import "RefreshTaskInput.h"

#import "PreferencesPanelControl.h"


@implementation RefreshTaskInput

// Overrides designated initialiser
- (instancetype) init {
  NSAssert(NO, @"Use initWithTreeSource:fileSizeMeasure:filterSet: instead");
  return [self initWithTreeSource: nil fileSizeMeasure: nil filterSet: nil];
}

- (instancetype) initWithTreeSource:(DirectoryItem *)treeSource
                    fileSizeMeasure:(NSString *)fileSizeMeasure
                          filterSet:(FilterSet *)filterSet {
  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;

  BOOL  showPackageContentsByDefault =
    [userDefaults boolForKey: ShowPackageContentsByDefaultKey] ? NSOnState : NSOffState;

  return [self initWithTreeSource: treeSource
                  fileSizeMeasure: fileSizeMeasure
                        filterSet: filterSet
                  packagesAsFiles: !showPackageContentsByDefault];
}

- (instancetype) initWithTreeSource:(DirectoryItem *)treeSource
                    fileSizeMeasure:(NSString *)fileSizeMeasure
                          filterSet:(FilterSet *)filterSet
                    packagesAsFiles:(BOOL) packagesAsFiles {
  if (self = [super init]) {
    _treeSource = [treeSource retain];
    _fileSizeMeasure = [fileSizeMeasure retain];
    _filterSet = [filterSet retain];
    _packagesAsFiles = packagesAsFiles;
  }
  return self;
}

- (void) dealloc {
  [_treeSource release];
  [_fileSizeMeasure release];
  [_filterSet release];

  [super dealloc];
}

@end
