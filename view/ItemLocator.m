#import "ItemLocator.h"

#import "FileItem.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"
#import "TreeLayoutBuilder.h"


@implementation ItemLocator

- (NSRect) locationForItem:(FileItem *)item
                    onPath:(NSArray *)itemPath
            startingAtTree:(FileItem *)treeRoot
        usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                    bounds:(NSRect)bounds {
  itemLocation = NSZeroRect;

  NSAssert(path == nil, @"path should be nil");
  path = itemPath; // Not retaining it. It is only needed during this method.
  targetItem = item;

  // Align the path with the tree, as the path may contain invisible items not part of the tree.
  pathIndex = 0;
  while (path[pathIndex] != treeRoot) {
    pathIndex++;

    NSAssert(pathIndex < path.count, @"treeRoot not found in path.");
  }

  [layoutBuilder layoutItemTree: treeRoot inRect: bounds traverser: self];

  path = nil;
  targetItem = nil;

  return itemLocation;
}

- (BOOL) descendIntoItem:(Item *)item atRect:(NSRect)rect depth:(int)depth {
  if (pathIndex >= path.count || path[pathIndex] != item) {
    return NO;
  }

  pathIndex++;
  itemLocation = rect;

  return item != targetItem;
}

- (void) emergedFromItem: (Item *)item {
  // void
}

@end
