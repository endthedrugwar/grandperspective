#import <Cocoa/Cocoa.h>

@class Item;
@class CompoundItem;

@interface TreeBalancer : NSObject {

@private
  // Temporary arrays
  NSMutableArray<CompoundItem *>  *compoundItems;
  NSMutableArray<Item *>  *itemArray;
}

+ (dispatch_queue_t)dispatchQueue;

// Balance tree with as input the items passed via a linked list of CompoundItems. These
// CompoundItems are re-used to create the balanced tree. This is a way to pass the request to
// another thread without requiring temporary storage whose ownership needs transferring (so it
// cannot be re-used without additional synchronization)
- (Item *)convertLinkedListToTree:(Item *)items;

@end
