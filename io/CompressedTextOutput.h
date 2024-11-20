#import <Foundation/Foundation.h>

#import <compression.h>
#import <zlib.h>

#import "TextOutput.h"

@interface CompressedTextOutput : TextOutput {

  void  *compressedDataBuffer;

  struct z_stream_s  outStream;
}

- (instancetype) init NS_DESIGNATED_INITIALIZER;

- (BOOL) flush;

@end
