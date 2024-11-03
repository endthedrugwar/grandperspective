#import <Foundation/Foundation.h>

#import "CompressedTextOutput.h"

@implementation CompressedTextOutput

- (instancetype) init:(NSString *)filename {
  if (self = [super init: filename]) {
    compressedDataBuffer = malloc(TEXT_OUTPUT_BUFFER_SIZE);

    compression_stream_init(&outStream, COMPRESSION_STREAM_ENCODE, COMPRESSION_ZLIB);
  }

  return self;
}

- (void) dealloc {
  free(compressedDataBuffer);

  compression_stream_destroy(&outStream);

  [super dealloc];
}

- (BOOL) flush {
  int flags = (dataBufferPos < TEXT_OUTPUT_BUFFER_SIZE) ? COMPRESSION_STREAM_FINALIZE : 0;

  outStream.src_ptr = dataBuffer;
  outStream.src_size = dataBufferPos;
  outStream.dst_ptr = compressedDataBuffer;
  outStream.dst_size = TEXT_OUTPUT_BUFFER_SIZE;

  compression_status result = compression_stream_process(&outStream, flags);
  if (result == COMPRESSION_STATUS_ERROR) {
    NSLog(@"Error invoking compression_stream_process");
    return NO;
  }

  if (flags && result != COMPRESSION_STATUS_END) {
    NSLog(@"Compression END state not reached");
    return NO;
  }

  NSUInteger  numAvail = TEXT_OUTPUT_BUFFER_SIZE - outStream.dst_size;
  NSLog(@"consumed = %lu, produced = %lu", dataBufferPos - outStream.src_size, numAvail);
  NSAssert(outStream.src_size == 0, @"Did not manage to consume all input");

  if (numAvail > 0) {
    NSUInteger  numWritten = fwrite(compressedDataBuffer, 1, numAvail, file);
    if (numWritten != numAvail) {
      NSLog(@"Failed to write compressed text data: %lu bytes written out of %lu.",
            (unsigned long)numWritten, (unsigned long)numAvail);
      return NO;
    }
  }

  dataBufferPos = 0;

  return YES;
}

@end // @implementation CompressedTextOutput
