//
//  TextOutput.h
//  GrandPerspective
//
//  Created by Erwin on 03/11/2024.
//

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
