#import "TreeLayoutBuilder.h"

#import "TreeLayoutTraverser.h"
#import "CompoundItem.h"
#import "DirectoryItem.h" // Also imports FileItem.h


@interface TreeLayoutBuilder (PrivateMethods) 
  - (void) layoutItemTree:(Item *)root
                   inRect:(NSRect)rect
                traverser:(NSObject <TreeLayoutTraverser> *)traverser
                    depth:(int)depth;
@end


@implementation TreeLayoutBuilder

- (void) layoutItemTree:(Item *)tree
                 inRect:(NSRect) bounds
              traverser:(NSObject <TreeLayoutTraverser> *)traverser {
  [self layoutItemTree: tree inRect: bounds traverser: traverser depth: 0];
}

@end // @implementation TreeLayoutBuilder


@implementation TreeLayoutBuilder (PrivateMethods)

- (void) layoutItemTree:(Item *)root inRect:(NSRect)rect
              traverser:(NSObject <TreeLayoutTraverser> *)traverser
                  depth:(int)depth {
  
  // Rectangle must enclose one or more pixel "centers", i.e. it must enclose a point (x+0.5, y+0.5)
  // where x, y are integer values. This means that the rectangle will be visible.
  if ( ( (int)(rect.origin.x + rect.size.width + 0.5f) - 
         (int)(rect.origin.x + 0.5f) <= 0 ) || 
       ( (int)(rect.origin.y + rect.size.height + 0.5f) -
         (int)(rect.origin.y + 0.5f) <= 0 ) ) {
    return;
  }
    
  if ( [traverser descendIntoItem: root atRect: rect depth: depth] ) {
    Item  *sub1 = nil;
    Item  *sub2 = nil;

    if (root.isVirtual) {
      sub1 = ((CompoundItem *)root).first;
      sub2 = ((CompoundItem *)root).second;
    }
    else if (((FileItem *)root).isDirectory) {
      sub1 = ((DirectoryItem *)root).fileItems;
      sub2 = ((DirectoryItem *)root).directoryItems;
      ++depth;
    }

    if (sub1 != nil && sub2 != nil) {
      // The common layout case (for all CompoundItems and many DirectoryItems)
      float  ratio = (root.itemSize > 0) ? (sub1.itemSize / (float)root.itemSize) : 0.50;
      NSRect  rect1;
      NSRect  rect2;

      if (NSWidth(rect) > NSHeight(rect)) {
        NSDivideRect(rect, &rect1, &rect2, ratio * NSWidth(rect), NSMaxXEdge);
      }
      else {
        NSDivideRect(rect, &rect1, &rect2, ratio * NSHeight(rect), NSMinYEdge);
      }

      [self layoutItemTree: sub1 inRect: rect1 traverser: traverser depth: depth];
      [self layoutItemTree: sub2 inRect: rect2 traverser: traverser depth: depth];
    }
    else if (sub1 != nil || sub2 != nil) {
      // This happens for directory items that contain only files or only sub-directories
      [self layoutItemTree: (sub1 != nil) ? sub1 : sub2
                    inRect: rect
                 traverser: traverser
                     depth: depth];
    }
  
    [traverser emergedFromItem: root];
  }
}

@end // @implementation TreeLayoutBuilder (PrivateMethods)
