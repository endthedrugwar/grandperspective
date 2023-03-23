#import "ScanProgressPanelControl.h"

#import "ScanTaskExecutor.h"
#import "ScanTaskInput.h"
#import "TreeBuilder.h"


@implementation ScanProgressPanelControl

- (NSString *)windowTitle {
  return (refreshBasedScan
          ? NSLocalizedString(@"Refresh in progress", @"Title of progress panel.")
          : NSLocalizedString(@"Scanning in progress", @"Title of progress panel."));
}

- (NSString *)progressDetailsFormat {
  return NSLocalizedString(@"Scanning %@", @"Message in progress panel while scanning");
}

- (NSString *)progressSummaryFormat {
  return (refreshBasedScan
          ? NSLocalizedString(@"%d folders processed",
                              @"Message in progress panel while executing refresh-based scan")
          : NSLocalizedString(@"%d folders scanned",
                              @"Message in progress panel while executing a full scan"));
}

- (NSString *)pathFromTaskInput:(id)taskInput {
  return ((ScanTaskInput *)taskInput).path;
}

- (NSDictionary *)progressInfo {
  return ((ScanTaskExecutor *)taskExecutor).progressInfo;
}

// Overrides method in super class
- (void) taskStartedWithInput:(id)taskInput
               cancelCallback:(NSObject *)callback
                     selector:(SEL)selector {
  refreshBasedScan = ((ScanTaskInput *)taskInput).treeSource != nil;

  [super taskStartedWithInput: taskInput cancelCallback: callback selector: selector];
}

@end // @implementation ScanProgressPanelControl
