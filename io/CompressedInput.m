#import <Foundation/Foundation.h>

#import "CompressedInput.h"

const NSUInteger COMPRESSED_BUFFER_SIZE = 4096 * 2;
const NSUInteger DECOMPRESSED_BUFFER_SIZE = 4096 * 16;

const NSUInteger GZIP_HEADER_SIZE = 10; // TODO: Make dynamic
const NSUInteger GZIP_FOOTER_SIZE = 8;

@interface CompressedInput (PrivateMethods)

- (void) process;
- (BOOL) processNewInput;
- (BOOL) writeNewOutput;
- (BOOL) decompress;
- (BOOL) finalize;
- (void) close;

@end

@implementation CompressedInput

- (instancetype) initWithSourceUrl:(NSURL *)sourceUrl
                      outputStream:(NSOutputStream *)outputStreamVal {
  if (self = [super init]) {
    outputStream = [outputStreamVal retain];

    inputStream = [[NSInputStream alloc] initWithURL: sourceUrl];

    // Get the input file size (so that the gzip-footer can be easily skipped.
    _inputFileSize = [[NSFileManager.defaultManager attributesOfItemAtPath: sourceUrl.path
                                                                     error: nil] fileSize];

    compressedDataBuffer = malloc(COMPRESSED_BUFFER_SIZE);
    decompressedDataBuffer = malloc(DECOMPRESSED_BUFFER_SIZE);
  }

  return self;
}

- (void) dealloc {
  [inputStream release];
  [outputStream release];

  free(compressedDataBuffer);
  free(decompressedDataBuffer);

  [super dealloc];
}

- (void) open {
  compression_stream_init(&compressionStream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB);

  [inputStream setDelegate: self];
  [outputStream setDelegate: self];

  inputDataAvailable = NO;
  inputEndEncountered = NO;
  decompressionDone = NO;
  numDecompressedBytesAvailable = 0;
  outputSpaceAvailable = NO;

  [inputStream scheduleInRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [inputStream open];

  [outputStream scheduleInRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [outputStream open];
}

// Stream event handler
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
  switch (eventCode) {
    case NSStreamEventHasBytesAvailable:
      NSAssert(stream == inputStream, @"Unexpected stream has bytes available");
      inputDataAvailable = YES;
      break;
    case NSStreamEventHasSpaceAvailable:
      NSAssert(stream == outputStream, @"Unexpected stream has space available");
      outputSpaceAvailable = YES;
      break;
    case NSStreamEventEndEncountered:
      NSAssert(stream == inputStream, @"Unexpected stream end encountered");
      inputEndEncountered = YES;
      break;
    case NSStreamEventErrorOccurred:
      return [self close];
    case NSStreamEventOpenCompleted:
    case NSStreamEventNone:
      break;
  }

  [self process];
}

@end // @implementation CompressedInput

@implementation CompressedInput (PrivateMethods)

- (void) process {
  while (numDecompressedBytesAvailable == 0 && inputDataAvailable) {
    if (![self processNewInput]) {
      NSLog(@"Error processing new input");
      return [self close];
    }
  }

  while (numDecompressedBytesAvailable > 0 && outputSpaceAvailable) {
    if (![self writeNewOutput]) {
      NSLog(@"Error writing new output");
      return [self close];
    }

    if (numDecompressedBytesAvailable == 0 && inputEndEncountered) {
      // Finalize the stream. This may generate more decompressed data.
      if (![self finalize]) {
        NSLog(@"Failed to finalize compressed input");
        return [self close];
      }
    }
  }

  if (numDecompressedBytesAvailable == 0 &&
      inputEndEncountered && (!isCompressed || decompressionDone)) {
    // All decompressed data has been processed
    [self close];
  }
}

- (BOOL) processNewInput {
  unsigned long long readSofar = self.totalBytesRead;

  NSInteger numRead = [inputStream read: compressedDataBuffer
                              maxLength: COMPRESSED_BUFFER_SIZE];
  compressionStream.src_ptr = compressedDataBuffer;
  compressionStream.src_size = numRead;
  NSLog(@"numRead = %ld", (long)numRead);

  if (readSofar == 0) {
    isCompressed = (compressedDataBuffer[0] == 0x1f && compressedDataBuffer[1] == 0x8b);

    if (isCompressed) {
      // Skip header
      compressionStream.src_ptr += GZIP_HEADER_SIZE;
      compressionStream.src_size -= GZIP_HEADER_SIZE;
    }
  }
  readSofar += numRead;
  self.totalBytesRead = readSofar;

  BOOL containsFooterBytes = isCompressed && readSofar > _inputFileSize - GZIP_FOOTER_SIZE;
  if (containsFooterBytes) {
    // Skip footer
    NSUInteger numFooterBytes = readSofar + GZIP_FOOTER_SIZE - _inputFileSize;
    compressionStream.src_size -= MIN(compressionStream.src_size, numFooterBytes);
  }

  if (![self decompress]) {
    return NO;
  }

  inputDataAvailable = inputStream.hasBytesAvailable;

  return YES;
}

- (BOOL) writeNewOutput {
  NSInteger numWritten = [outputStream write: decompressedDataP
                                   maxLength: numDecompressedBytesAvailable];
  NSLog(@"numWritten = %ld", (long)numWritten);

  if (numWritten < 0) {
    NSError  *error = outputStream.streamError;
    NSLog(@"Error writing to stream: %@", error.localizedDescription);
    return NO;
  }

  decompressedDataP += numWritten;
  numDecompressedBytesAvailable -= numWritten;

  outputSpaceAvailable = outputStream.hasSpaceAvailable;

  return YES;
}

- (BOOL) finalize {
  NSAssert(inputEndEncountered, @"Finalizing without encountering input end");
  if (isCompressed) {
    compressionStream.src_ptr = compressedDataBuffer;
    compressionStream.src_size = 0;

    return [self decompress];
  } else {
    return YES;
  }
}

- (void) close {
  [inputStream removeFromRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [inputStream close];

  [outputStream removeFromRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [outputStream close];
}

- (BOOL) decompress {
  NSAssert(numDecompressedBytesAvailable == 0,
           @"New decompress initiated while old data is still available");

  if (isCompressed) {
    int flags = inputEndEncountered ? COMPRESSION_STREAM_FINALIZE : 0;

    compressionStream.dst_ptr = decompressedDataBuffer;
    compressionStream.dst_size = DECOMPRESSED_BUFFER_SIZE;

    compression_status result = compression_stream_process(&compressionStream, flags);
    if (result == COMPRESSION_STATUS_ERROR) {
      NSLog(@"Error invoking compression_stream_process");
      return NO;
    }

    decompressionDone = (result == COMPRESSION_STATUS_END);

    numDecompressedBytesAvailable = DECOMPRESSED_BUFFER_SIZE - compressionStream.dst_size;
    decompressedDataP = decompressedDataBuffer;
    if (numDecompressedBytesAvailable == 0) {
      NSLog(@"Warning: No data after decompression");
      return YES;
    }
  } else {
    numDecompressedBytesAvailable = compressionStream.src_size;
    decompressedDataP = compressedDataBuffer;
  }

  if (numDecompressedBytesAvailable > 0 && outputSpaceAvailable) {
    if (! [self writeNewOutput]) {
      return NO;
    }
  }

  return YES;
}

@end
