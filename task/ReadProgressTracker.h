#import "ProgressTracker.h"

@interface ReadProgressTracker : ProgressTracker {
  unsigned long long inputFileSize;
  unsigned long long bytesRead;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithInputFile:(NSURL *)inputFile NS_DESIGNATED_INITIALIZER;

- (void) processingFolder:(DirectoryItem *)dirItem bytesRead:(unsigned long long)bytesRead;

@end
