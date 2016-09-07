#import "ScanProgressTracker.h"

@interface ScanProgressTracker (PrivateMethods)

- (void) processedOrSkippedFolder: (DirectoryItem *)dirItem;

@end

@implementation ScanProgressTracker

- (void) setNumSubFolders: (int)num {
  [mutex lock];

  if (level <= NUM_PROGRESS_ESTIMATE_LEVELS) {
    if (num > 0) {
      numSubFolders[level - 1] = num;
    } else {
      // Make both equal (and non-zero), to simplify calculation by
      // estimatedProgress.
      numSubFoldersProcessed[level - 1] = numSubFolders[level - 1];
    }
  }

  [mutex unlock];
}

- (void) _processingFolder: (DirectoryItem *)dirItem {
  [super _processingFolder: dirItem];

  if (level <= NUM_PROGRESS_ESTIMATE_LEVELS) {
    // Set to non-zero until actually set by setNumSubFolders, to simplify
    // calculation by estimatedProgress.
    numSubFolders[level - 1] = 1;
    numSubFoldersProcessed[level - 1] = 0;
  }
}

- (void) _processedFolder: (DirectoryItem *)dirItem {
  [super _processedFolder: dirItem];
  [self processedOrSkippedFolder: dirItem];
}

- (void) _skippedFolder: (DirectoryItem *)dirItem {
  [super _skippedFolder: dirItem];
  [self processedOrSkippedFolder: dirItem];
}

- (float) estimatedProgress {
  float progress = 0;
  float fraction = 100;
  int i = 0;
  int max_i = MIN(level, NUM_PROGRESS_ESTIMATE_LEVELS);
  while (i < max_i) {
    progress += fraction * numSubFoldersProcessed[i] / numSubFolders[i];
    fraction /= numSubFolders[i];
    i++;
  }
  NSAssert(progress >= 0, @"Progress should be positive");
  NSAssert(progress <= 100, @"Progress should be less than 100");

  return progress;
}

@end


@implementation ScanProgressTracker (PrivateMethods)

- (void) processedOrSkippedFolder: (DirectoryItem *)dirItem {
  if (level > 0 && level <= NUM_PROGRESS_ESTIMATE_LEVELS) {
    numSubFoldersProcessed[level - 1] += 1;
    NSAssert(numSubFoldersProcessed[level - 1] <= numSubFolders[level - 1],
             @"More sub-folders processed than expected.");
  }
}

@end