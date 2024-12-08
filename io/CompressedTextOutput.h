#import <Foundation/Foundation.h>

#import <compression.h>
#import <zlib.h>

#import "TextOutput.h"

@interface CompressedTextOutput : TextOutput {

  void  *compressedDataBuffer;

  struct z_stream_s  outStream;
}

- (instancetype) initWithPath:(NSURL *)path NS_DESIGNATED_INITIALIZER;

- (BOOL) flush;

@end
