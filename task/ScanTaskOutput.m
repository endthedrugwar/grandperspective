#import "ScanTaskOutput.h"

#import "AlertMessage.h"
#import "TreeContext.h"

@implementation ScanTaskOutput

+ (instancetype) scanTaskOutput:(TreeContext *)treeContext alert:(AlertMessage *)alert {
  return [[[ScanTaskOutput alloc] initWithTreeContext: treeContext alert: alert] autorelease];
}

+ (instancetype) failedScanTaskOutput:(AlertMessage *)alert {
  return [[[ScanTaskOutput alloc] initWithTreeContext: nil alert: alert] autorelease];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContext alert:(AlertMessage *)alert {
  if (self = [super init]) {
    NSAssert(treeContext != nil || alert != nil, @"treeContext or alert must be set.");

    _treeContext = [treeContext retain];
    _alert = [alert retain];
  }
  return self;
}

- (void) dealloc {
  [_treeContext release];
  [_alert release];

  [super dealloc];
}

@end
