#import <Cocoa/Cocoa.h>

#import "TaskExecutor.h"

@class TreeRefresher;


extern NSString  *RefreshTaskAbortedEvent;

@interface RefreshTaskExecutor : NSObject <TaskExecutor> {
  TreeRefresher  *treeRefresher;

  NSLock  *taskLock;
}


/* Returns a dictionary with info about the progress of the scan task that is currently being
 * executed (or nil if there is none). The keys in the dictionary are those used by ProgressTracker.
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

@end
