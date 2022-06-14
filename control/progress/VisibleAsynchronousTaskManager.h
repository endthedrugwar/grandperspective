#import <Cocoa/Cocoa.h>


@class AsynchronousTaskManager;
@class ProgressPanelControl;

/* Wraps around an AsynchronousTaskManager to show a progress panel whenever a task is run in the
 * background.
 */
@interface VisibleAsynchronousTaskManager : NSObject {

  AsynchronousTaskManager  *taskManager;
  ProgressPanelControl  *progressPanelControl;

}

// Overrides super's designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithProgressPanel:(ProgressPanelControl *)panelControl NS_DESIGNATED_INITIALIZER;

- (void) dispose;

- (void) abortTask;

- (void) asynchronouslyRunTaskWithInput:(id)input
                               callback:(NSObject *)callback
                               selector:(SEL)selector;

@end
