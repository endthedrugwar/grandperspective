#import <Cocoa/Cocoa.h>
#import "Compatibility.h"

@class DirectoryView;

@interface ColorLegendTableViewControl : NSObject <NSTableViewDataSource> {

  DirectoryView  *dirView;
  NSTableView  *tableView;
  NSMutableArray  *colorImages;

}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithDirectoryView:(DirectoryView *)dirView
                             tableView:(NSTableView *)tableView NS_DESIGNATED_INITIALIZER;

@end
