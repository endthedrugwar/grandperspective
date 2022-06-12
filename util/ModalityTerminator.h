#import <Cocoa/Cocoa.h>


@interface ModalityTerminator : NSObject {
}

+ (ModalityTerminator *)modalityTerminatorForEventSource:(NSObject *)source;

// Overrides designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithEventSource:(NSObject *)eventSource NS_DESIGNATED_INITIALIZER;

- (void) abortModalAction:(NSNotification *)notification;
- (void) stopModalAction:(NSNotification *)notification;

@end
