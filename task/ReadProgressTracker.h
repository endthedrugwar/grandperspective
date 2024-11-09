#import "ProgressTracker.h"

@interface ReadProgressTracker : ProgressTracker {
  // The total number of lines in the input file
  NSInteger  totalLines;

  // The number of lines processed sofar.
  NSInteger  processedLines;
}

- (void) processingFolder:(DirectoryItem *)dirItem
           processedLines:(NSInteger)numProcessed;

@end
