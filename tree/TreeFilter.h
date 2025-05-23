#import <Cocoa/Cocoa.h>


@class FilterSet;
@class FilteredTreeGuide;
@class TreeBalancer;
@class TreeContext;
@class ProgressTracker;


@interface TreeFilter : NSObject {
  FilterSet  *filterSet;

  FilteredTreeGuide  *treeGuide;
  TreeBalancer  *treeBalancer;

  BOOL  abort;
  
  ProgressTracker  *progressTracker;
}

// Overrides super's designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithFilterSet:(FilterSet *)filterSet NS_DESIGNATED_INITIALIZER;


/* Filters the tree. Omits all items from the old tree that should not be descended into according
 * to the filtered tree guide.
 */
- (TreeContext *)filterTree:(TreeContext *)oldTree;

/* Aborts filtering (when it is carried out in a different execution thread). 
 */
- (void) abort;

/* Returns a dictionary containing information about the progress of the ongoing tree-filtering
 * task.
 *
 * It can safely be invoked from a different thread than the one that invoked -filterTree: (and not
 * doing so would actually be quite silly).
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

@end
