#import <Foundation/Foundation.h>

#import "TreeLayoutTraverser.h"

@class FileItem;
@class ItemPathModelView;
@class TreeLayoutBuilder;

@interface ItemLocator : NSObject <TreeLayoutTraverser> {
  // All variables below are temporary variables used while building the path. They are not
  // retained, as they are only used during a single recursive invocation.

  NSArray  *path;
  FileItem  *targetItem;
  unsigned int  pathIndex;
  NSRect  itemLocation;
}

- (NSRect) locationForItem:(FileItem *)item
                    onPath:(NSArray *)itemPath
            startingAtTree:(FileItem *)treeRoot
        usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                    bounds:(NSRect)bounds;

@end
