#import <Cocoa/Cocoa.h>

#import "ProgressPanelControl.h"


@interface ScanProgressPanelControl : ProgressPanelControl {
  // True when instead of a full scan a (quick) refresh is being used
  BOOL  refreshBasedScan;
}

@end
