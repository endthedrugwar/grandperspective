#import <Cocoa/Cocoa.h>


@class Item;

@interface TreeBalancer : NSObject {

@private
  NSMutableArray  *tmpArray;
  NSMutableArray  *tmpArray2;
}

+ (dispatch_queue_t)dispatchQueue;

// Note: assumes that array may be modified for sorting!
- (Item *)createTreeForItems:(NSMutableArray *)items;

// Balance tree with as input the items passed via a linked list of CompoundItems. These
// CompoundItems are re-used to create the balanced tree. This is a way to pass the request to
// another thread without requiring temporary storage whose ownership needs transferring (so it
// cannot be re-used without additional synchronization)
- (Item *)convertLinkedListToTree:(Item *)items;

@end
