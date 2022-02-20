#import "AlertMessage.h"

@implementation AlertMessage

- (void) dealloc {
  [_messageText release];
  [_informativeText release];

  [super dealloc];
}

@end
