#import <Cocoa/Cocoa.h>

#include "TreeDrawerBase.h"

@class TreeDrawerSettings;
@class FileItemTest;
@protocol FileItemMapping;

@interface TreeDrawer : TreeDrawerBase {
  NSObject <FileItemMapping>  *colorMapper;
  
  UInt32  freeSpaceColor;
  UInt32  usedSpaceColor;
  UInt32  visibleTreeBackgroundColor;
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree
               treeDrawerSettings:(TreeDrawerSettings *)settings NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) FileItemTest *maskTest;

@property (nonatomic, strong) NSObject<FileItemMapping> *colorMapper;

@end
