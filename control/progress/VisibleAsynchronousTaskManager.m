#import "VisibleAsynchronousTaskManager.h"


#import "AsynchronousTaskManager.h"
#import "ProgressPanelControl.h"


@interface CallbackHandler : NSObject { 
  ProgressPanelControl  *progressPanelControl;

  NSObject  *callback;
  SEL  callbackSelector; 
}

// Overrides designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithProgressPanel:(ProgressPanelControl *)progressPanel
                              callback:(NSObject *)callback
                              selector:(SEL)selector NS_DESIGNATED_INITIALIZER;
         
- (void) taskDone:(id)result;

@end // @interface CallbackHandler


@implementation VisibleAsynchronousTaskManager

- (instancetype) initWithProgressPanel:(ProgressPanelControl *)panelControl {
  if (self = [super init]) {
    progressPanelControl = [panelControl retain];
    
    taskManager = [[AsynchronousTaskManager alloc] initWithTaskExecutor:
                   progressPanelControl.taskExecutor];
  }

  return self;
}

- (void) dealloc {
  [taskManager release];
  [progressPanelControl release];

  [super dealloc];
}

- (void) dispose {
  NSAssert( taskManager != nil, @"TaskManager already nil.");
  [taskManager dispose];

  // Set it to "nil" to prevent it from being disposed once more.
  [taskManager release];
  taskManager = nil;
}


- (void) abortTask {
  [taskManager abortTask];
}


- (void) asynchronouslyRunTaskWithInput:(id)input
                               callback:(NSObject *)callback
                               selector:(SEL)selector {
  // Show the progress panel and let its Cancel button abort the task.
  [progressPanelControl taskStartedWithInput: input
                              cancelCallback: taskManager
                                    selector: @selector(abortTask) ];

  CallbackHandler  *callbackHandler = 
    [[[CallbackHandler alloc] initWithProgressPanel: progressPanelControl
                                           callback: callback
                                           selector: selector] autorelease];

  // Let callback go through handler object, so that progress panel is also closed.
  [taskManager asynchronouslyRunTaskWithInput: input 
                                     callback: callbackHandler
                                     selector: @selector(taskDone:)];
}

@end // @implementation VisibleAsynchronousTaskManager


@implementation CallbackHandler

- (instancetype) initWithProgressPanel:(ProgressPanelControl *)panelControl
                              callback:(NSObject *)callbackVal
                              selector:(SEL)selector {

  if (self = [super init]) {
    progressPanelControl = [panelControl retain];
    callback = [callbackVal retain];
    callbackSelector = selector;
  }
  
  return self;
}

- (void) dealloc {
  [progressPanelControl release];
  [callback release];
  
  [super dealloc];
}

- (void) taskDone:(id)result {
  [progressPanelControl taskStopped];
  
  [callback performSelector: callbackSelector withObject: result];
}

@end // @implementation CallbackHandler
