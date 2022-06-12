#import "TreeBalancer.h"

#import "Item.h"
#import "CompoundItem.h"
#import "PeekingEnumerator.h"

@implementation TreeBalancer

- (instancetype) init {
  if (self = [super init]) {
    tmpArray = [[NSMutableArray alloc] initWithCapacity: 1024];
  }
  
  return self;
}

- (void) dealloc {
  [tmpArray release];

  [super dealloc];
}


// Note: assumes that array may be modified for sorting!
- (Item *)createTreeForItems:(NSMutableArray *)items {

  if (items.count == 0) {
    // No items, so nothing needs doing: return immediately.
    return nil;
  }
  
  [items sortUsingComparator: ^(Item *item1, Item *item2) {
    if (item1.itemSize < item2.itemSize) {
      return NSOrderedAscending;
    }
    if (item1.itemSize > item2.itemSize) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];

  // Not using auto-release to minimise size of auto-release pool.
  PeekingEnumerator  *sortedItems = 
    [[PeekingEnumerator alloc] initWithEnumerator: items.objectEnumerator];

  // Exclude zero-sized items
  while (sortedItems.peekObject != nil && ((Item*)sortedItems.peekObject).itemSize == 0) {
    [sortedItems nextObject];
  }
  
  NSMutableArray<Item *>  *sortedBranches = tmpArray;
  NSAssert(tmpArray != nil && tmpArray.count == 0, @"Temporary array not valid." );
  
  int  branchesGetIndex = 0;

  while (YES) {
    Item  *first = nil;
    Item  *second = nil;

    while (second == nil) {
      Item*  smallest;

      if (
        // Out of leafs, or
        sortedItems.peekObject == nil || (
          // orphaned branches exist, and
          branchesGetIndex < sortedBranches.count &&
          // the branch is smaller.
          sortedBranches[branchesGetIndex].itemSize < ((Item *)sortedItems.peekObject).itemSize
        )
      ) {
        if (branchesGetIndex < sortedBranches.count) {
          smallest = sortedBranches[branchesGetIndex++];
        }
        else {
          // We're finished building the tree
          
          // As zero-sized items are excluded, first can actually be nil but that is okay.
          [first retain];
        
          // Clean up
          [sortedBranches removeAllObjects]; // Keep array for next time.
          [sortedItems release];
          
          return [first autorelease];
        }
      }
      else {
        smallest = [sortedItems nextObject];
      }
      NSAssert(smallest != nil, @"Smallest is nil.");
      
      if (first == nil) {
        first = smallest;
      }
      else {
        second = smallest;
      }
    }
    
    id  newBranch = [[CompoundItem allocWithZone: first.zone] initWithFirst: first second: second];
    [sortedBranches addObject: newBranch];
    [newBranch release]; // Not auto-releasing to minimise size of auto-release pool.
  }
}

@end // @implementation TreeBalancer
