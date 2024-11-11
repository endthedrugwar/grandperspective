#import <Foundation/Foundation.h>

#import <compression.h>

#import "TextOutput.h"

@interface CompressedTextOutput : TextOutput {

  void  *compressedDataBuffer;
  uint32_t  originalSize;
  unsigned long  crc;

  compression_stream  outStream;
}

- (instancetype) init NS_DESIGNATED_INITIALIZER;

- (BOOL) open:(NSString *)filename;
- (BOOL) close;
- (BOOL) flush;

@end
