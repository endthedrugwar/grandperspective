#import <Foundation/Foundation.h>

#import <compression.h>

extern const NSUInteger DECOMPRESSED_BUFFER_SIZE;

@interface CompressedInput : NSObject <NSStreamDelegate> {

  void  *compressedDataBuffer;
  void  *decompressedDataBuffer;

  BOOL  inputDataAvailable;
  BOOL  inputEndEncountered;
  BOOL  decompressionDone;
  NSInteger numDecompressedBytesAvailable;
  BOOL  outputSpaceAvailable;

  compression_stream  compressionStream;
  NSInputStream  *inputStream;
  NSOutputStream  *outputStream;
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithSourceUrl:(NSURL *)sourceUrl
                      outputStream:(NSOutputStream *)outputStream NS_DESIGNATED_INITIALIZER;

- (void) open;

// Stream event handler
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode;

@end
