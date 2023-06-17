#import "TreeBalancer.h"

#import "Item.h"
#import "CompoundItem.h"
#import "PeekingEnumerator.h"

@implementation TreeBalancer

+ (dispatch_queue_t)dispatchQueue {
  static dispatch_queue_t  queue;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    queue = dispatch_queue_create("net.sourceforge.grandperspectiv.TreeBalancer",
                                  DISPATCH_QUEUE_SERIAL);
  });

  return queue;
}


- (instancetype) init {
  if (self = [super init]) {
    tmpArray = [[NSMutableArray alloc] initWithCapacity: 1024];
    tmpArray2 = [[NSMutableArray alloc] initWithCapacity: 1024];
  }
  
  return self;
}

- (void) dealloc {
  [tmpArray release];
  [tmpArray2 release];

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
    
    id  newBranch = [[CompoundItem alloc] initWithFirst: first second: second];
    [sortedBranches addObject: newBranch];
    [newBranch release]; // Not auto-releasing to minimise size of auto-release pool.
  }
}

- (Item *)convertLinkedListToTree:(Item *)items {
  if (items == nil || !items.virtual) {
    // Handle zero or one item here (so that rest of code knows there's at least one CompoundItem)
    return items;
  }

  // Copy CompoundItems to separate array, for later re-use.
  // Also copy actual file items to item array, for sorting.
  NSAssert(tmpArray != nil && tmpArray.count == 0, @"Temporary array not valid." );
  NSMutableArray<CompoundItem *>  *compoundItems = tmpArray;
  NSAssert(tmpArray2 != nil && tmpArray2.count == 0, @"Temporary array not valid." );
  NSMutableArray<Item *>  *itemArray = tmpArray2;

  Item  *item = items;
  while (item.isVirtual) {
    CompoundItem  *compoundItem = (CompoundItem *)item;
    [compoundItems addObject: compoundItem];
    [itemArray addObject: compoundItem.first];
    item = compoundItem.second;
  }
  [itemArray addObject: compoundItems.lastObject.second];

  [itemArray sortUsingComparator: ^(Item *item1, Item *item2) {
    if (item1.itemSize < item2.itemSize) {
      return NSOrderedAscending;
    }
    if (item1.itemSize > item2.itemSize) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];

  // Not using auto-release to minimise size of auto-release pool (and to enable running in
  // dispatch queue without auto-release pool).
  PeekingEnumerator  *sortedItems =
    [[PeekingEnumerator alloc] initWithEnumerator: itemArray.objectEnumerator];

  // The index from where to get the next uninitialized Compound Item
  int  i = 0;
  // The index from where to get the first initialized but orphaned Compound Item (when j < i)
  int  j = 0;

  while (YES) {
    Item  *first = nil;
    Item  *second = nil;

    while (second == nil) {
      Item*  smallest;

      if (
        // Out of leafs, or
        sortedItems.peekObject == nil || (
          // orphaned branches exist, and the branch is smaller
          j < i && compoundItems[j].itemSize < ((Item *)sortedItems.peekObject).itemSize
        )
      ) {
        if (j < i) {
          smallest = compoundItems[j++];
        } else {
          // We're finished building the tree

          // As zero-sized items are excluded, first can actually be nil but that is okay.
          [first retain];

          // Clean up
          [itemArray removeAllObjects];
          [compoundItems removeAllObjects];
          [sortedItems release];

          return [first autorelease];
        }
      } else {
        smallest = [sortedItems nextObject];
      }
      NSAssert(smallest != nil, @"Smallest is nil.");

      if (first == nil) {
        first = smallest;
      } else {
        second = smallest;
      }
    }

    [compoundItems[i] clear];
    [compoundItems[i++] initWithFirst: first second: second];
  }
}

@end // @implementation TreeBalancer
