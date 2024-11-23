#import <Foundation/Foundation.h>

#import <zlib.h>

extern const NSUInteger DECOMPRESSED_BUFFER_SIZE;

// Reads gzip-ed compressed data, de-compressing it on the fly.
//
// For backward compatibility, it also supports reading uncompressed text data
@interface CompressedInput : NSObject <NSStreamDelegate> {

  uint8_t  *compressedDataBuffer;
  void  *decompressedDataBuffer;

  BOOL  isCompressed;

  BOOL  inputDataAvailable;
  BOOL  inputEndEncountered;
  BOOL  decompressionDone;
  const uint8_t  *decompressedDataP;
  NSInteger numDecompressedBytesAvailable;
  BOOL  outputSpaceAvailable;

  struct z_stream_s  compressionStream;

  NSInputStream  *inputStream;
  NSOutputStream  *outputStream;
}

@property (nonatomic) unsigned long long inputFileSize;
@property (atomic) unsigned long long totalBytesRead;

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithSourceUrl:(NSURL *)sourceUrl
                      outputStream:(NSOutputStream *)outputStream NS_DESIGNATED_INITIALIZER;

- (void) open;

// Stream event handler
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode;

@end
