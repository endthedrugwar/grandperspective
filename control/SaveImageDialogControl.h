#import <Cocoa/Cocoa.h>


@class DirectoryViewControl;

/* A one-shot image saving device. It disposes after having done its job.
 */
@interface SaveImageDialogControl : NSWindowController {
  IBOutlet NSTextField  *widthField;
  IBOutlet NSTextField  *heightField;

  DirectoryViewControl  *dirViewControl;
}

// Override designated initialisers
- (instancetype) initWithWindow:(NSWindow *)window NS_UNAVAILABLE;
- (instancetype) initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype) initWithDirectoryViewControl:(DirectoryViewControl *)dirViewControl NS_DESIGNATED_INITIALIZER;

- (IBAction)valueEntered:(id)sender;
- (IBAction)cancelSaveImage:(id)sender;
- (IBAction)saveImage:(id)sender;

@end
