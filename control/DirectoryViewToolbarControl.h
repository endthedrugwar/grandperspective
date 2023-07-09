#import <Cocoa/Cocoa.h>

@class DirectoryViewControl;

@interface DirectoryViewToolbarControl
  : NSObject <NSToolbarDelegate, NSMenuItemValidation, NSToolbarItemValidation> {

  IBOutlet NSWindow  *dirViewWindow;

  IBOutlet NSSegmentedControl  *zoomControls;
  IBOutlet NSSegmentedControl  *focusControls;
  
  NSUInteger  zoomInSegment;
  NSUInteger  zoomOutSegment;
  NSUInteger  zoomResetSegment;

  NSUInteger  focusUpSegment;
  NSUInteger  focusDownSegment;
  NSUInteger  focusResetSegment;

  DirectoryViewControl  *dirViewControl;
}

@end
