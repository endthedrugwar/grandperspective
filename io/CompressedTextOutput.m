#import <zlib.h>

#import "CompressedTextOutput.h"

@implementation CompressedTextOutput

- (instancetype) init {
  if (self = [super init]) {
    compressedDataBuffer = malloc(TEXT_OUTPUT_BUFFER_SIZE);

    outStream.zalloc = Z_NULL;
    outStream.zfree = Z_NULL;
    int result = deflateInit2(&outStream,
                              Z_DEFAULT_COMPRESSION,
                              Z_DEFLATED,
                              15 + 16, // Default window size with GZIP format enabled
                              9,
                              Z_DEFAULT_STRATEGY);
    NSAssert(result == Z_OK, @"deflateInit2 failed");
  }

  return self;
}

- (void) dealloc {
  free(compressedDataBuffer);

  deflateEnd(&outStream);

  [super dealloc];
}

- (BOOL) flush {
  int flush = (dataBufferPos < TEXT_OUTPUT_BUFFER_SIZE) ? Z_FINISH : Z_NO_FLUSH;

  outStream.next_in = dataBuffer;
  outStream.avail_in = (unsigned int)dataBufferPos;

  int result;
  do {
    outStream.next_out = compressedDataBuffer;
    outStream.avail_out = (unsigned int)TEXT_OUTPUT_BUFFER_SIZE;

    result = deflate(&outStream, flush);
    if (result == Z_STREAM_ERROR || result == Z_BUF_ERROR) {
      NSLog(@"Error invoking deflate: %d", result);
      return NO;
    }

    NSUInteger  numProduced = TEXT_OUTPUT_BUFFER_SIZE - outStream.avail_out;
    NSUInteger  numConsumed = dataBufferPos - outStream.avail_in;
    NSLog(@"consumed = %lu, produced = %lu", numConsumed, numProduced);

    if (numProduced > 0) {
      NSUInteger  numWritten = fwrite(compressedDataBuffer, 1, numProduced, file);
      if (numWritten != numProduced) {
        NSLog(@"Failed to write compressed text data: %lu bytes written out of %lu.",
              (unsigned long)numWritten, (unsigned long)numProduced);
        return NO;
      }
    }
  } while (outStream.avail_in > 0 || (flush == Z_FINISH && result != Z_STREAM_END));

  dataBufferPos = 0;
  return YES;
}

@end // @implementation CompressedTextOutput
