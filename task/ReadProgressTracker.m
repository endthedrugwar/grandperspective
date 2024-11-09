#import "ReadProgressTracker.h"

@implementation ReadProgressTracker

- (instancetype) init {
  if (self = [super init]) {
    totalLines = 0;
    processedLines = 0;
  }

  return self;
}

- (void) processingFolder:(DirectoryItem *)dirItem
           processedLines:(NSInteger)numProcessed {
  [mutex lock];

  // For efficiency, call internal method that assumes mutex has been locked.
  [self _processingFolder: dirItem];

//  NSAssert(numProcessed <= totalLines,
//           @"More lines processed than expected (%ld > %ld).",
//           (long)numProcessed, (long)totalLines);
//  processedLines = numProcessed;

  [mutex unlock];
}


- (float) estimatedProgress {
  if (totalLines == 0) {
    return 0;
  } else {
    return 100.0 * processedLines / totalLines;
  }
}

@end
