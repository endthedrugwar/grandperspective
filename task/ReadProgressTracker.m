#import "ReadProgressTracker.h"

@implementation ReadProgressTracker

- (instancetype) initWithInputFile:(NSURL *)inputFile {
  if (self = [super init]) {
    inputFileSize = [[NSFileManager.defaultManager attributesOfItemAtPath: inputFile.path
                                                                    error: nil] fileSize];
    bytesRead = 0;
  }

  return self;
}

- (void) processingFolder:(DirectoryItem *)dirItem bytesRead:(unsigned long long)bytesReadVal {
  [mutex lock];

  // For efficiency, call internal method that assumes mutex has been locked.
  [self _processingFolder: dirItem];

  bytesRead = bytesReadVal;

  [mutex unlock];
}


- (float) estimatedProgress {
  return inputFileSize > 0 ? 100.0 * bytesRead / inputFileSize : 0;
}

@end
