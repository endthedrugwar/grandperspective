#import <zlib.h>

#import "CompressedTextOutput.h"

@implementation CompressedTextOutput

- (instancetype) init {
  if (self = [super init]) {
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

- (BOOL) open:(NSString *)filename {
  if (![super open: filename]) {
    return NO;
  }

  originalSize = 0;
  crc = crc32(0L, Z_NULL, 0);

  int8_t header[] = {
    0x1f, 0x8b,             // GZIP ID
    0x08,                   // Compression method - DEFLATE
    0x01,                   // Flags: FTEXT
    0x00, 0x00, 0x00, 0x00, // Modification time: unset
    0x00,                   // Extra flags
    0x07                    // OS: Macintosh
  };
  return fwrite(header, 1, sizeof(header), file) == sizeof(header);
}

- (BOOL) close {
  BOOL ok = (fwrite(&crc, 4, 1, file) == 1 &&
             fwrite(&originalSize, 4, 1, file) == 1);

  return [super close] && ok;
}

- (BOOL) flush {
  int flags = (dataBufferPos < TEXT_OUTPUT_BUFFER_SIZE) ? COMPRESSION_STREAM_FINALIZE : 0;

  outStream.src_ptr = dataBuffer;
  outStream.src_size = dataBufferPos;
  outStream.dst_ptr = compressedDataBuffer;
  outStream.dst_size = TEXT_OUTPUT_BUFFER_SIZE;

  originalSize += dataBufferPos;

  crc = crc32(crc, dataBuffer, (unsigned int)dataBufferPos);

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
