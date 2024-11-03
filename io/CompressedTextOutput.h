#import <Foundation/Foundation.h>

#import <compression.h>

#import "TextOutput.h"

@interface CompressedTextOutput : TextOutput {

  void  *compressedDataBuffer;

  compression_stream  outStream;
}

- (instancetype) init:(NSString *)filename NS_DESIGNATED_INITIALIZER;

- (BOOL) flush;

@end
