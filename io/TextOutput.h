extern const NSUInteger TEXT_OUTPUT_BUFFER_SIZE;

@interface TextOutput : NSObject {
  FILE  *file;

  void  *dataBuffer;
  NSUInteger  dataBufferPos;
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) init:(NSString *)filename NS_DESIGNATED_INITIALIZER;

- (BOOL) appendString:(NSString *)s;
- (BOOL) flush;

@end
