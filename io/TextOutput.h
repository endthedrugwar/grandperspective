extern const NSUInteger TEXT_OUTPUT_BUFFER_SIZE;

@interface TextOutput : NSObject {
  FILE  *file;

  void  *dataBuffer;
  NSUInteger  dataBufferPos;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithPath:(NSURL *)path NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readonly) NSURL *path;

- (BOOL) open;
- (BOOL) close;

- (BOOL) appendString:(NSString *)s;
- (BOOL) flush;

@end
