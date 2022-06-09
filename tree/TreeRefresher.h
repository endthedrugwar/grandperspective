#import <Cocoa/Cocoa.h>

#import "TreeBuilder.h"

@class DirectoryItem;

/* Refreshes an existing tree by rescanning directories as needed based on their rescan flags.
 */
@interface TreeRefresher : TreeBuilder {
  DirectoryItem  *oldTree;
  BOOL  hardLinkMismatch;
}

- (instancetype) initWithFilterSet:(FilterSet *)filterSet
                           oldTree:(DirectoryItem *)oldTree NS_DESIGNATED_INITIALIZER;

@end

@interface TreeRefresher (ProtectedMethods)

/* Constructs a tree for the given folder. It is used to implement buildTreeForPath:
 *
 * Overrides method in parent class to provide refresh implementation.
 */
- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path;

- (AlertMessage *)createAlertMessage:(DirectoryItem *)scanTree;

@end
