//
//  TextOutput.m
//  GrandPerspective
//
//  Created by Erwin on 03/11/2024.
//

#import <Foundation/Foundation.h>

#import "TextOutput.h"

static const NSUInteger BUFFER_SIZE = 4096 * 16;


@implementation TextOutput

- (void) dealloc {
  fclose(file);
  file = NULL;

  free(dataBuffer);

  [super dealloc];
}

- (instancetype) init:(NSString *)filename {
  if (self = [super init]) {
    file = fopen( filename.UTF8String, "w");
    if (!file) {
      return nil;
    }

    dataBuffer = malloc(BUFFER_SIZE);
  }
  return self;
}

- (BOOL) appendString:(NSString *)s {
  NSData  *newData = [s dataUsingEncoding: NSUTF8StringEncoding];
  const void  *newDataBytes = newData.bytes;
  NSUInteger  numToAppend = newData.length;
  NSUInteger  newDataPos = 0;

  while (numToAppend > 0) {
    NSUInteger  numToCopy = ( (dataBufferPos + numToAppend <= BUFFER_SIZE)
                             ? numToAppend
                             : BUFFER_SIZE - dataBufferPos );

    memcpy(dataBuffer + dataBufferPos, newDataBytes + newDataPos, numToCopy);
    dataBufferPos += numToCopy;
    newDataPos += numToCopy;
    numToAppend -= numToCopy;

    if (dataBufferPos == BUFFER_SIZE) {
      NSUInteger  numWritten = fwrite(dataBuffer, 1, BUFFER_SIZE, file);

      if (numWritten != BUFFER_SIZE) {
        NSLog(@"Failed to write entire buffer, %lu bytes written", (unsigned long)numWritten);
        return NO;
      }

      dataBufferPos = 0;
    }
  }

  return YES;
}

- (BOOL) flush {
  if (dataBufferPos > 0) {
    // Write remaining characters in buffer
    NSUInteger  numWritten = fwrite(dataBuffer, 1, dataBufferPos, file);

    if (numWritten != dataBufferPos) {
      NSLog(@"Failed to write last data: %lu bytes written out of %lu.",
            (unsigned long)numWritten, (unsigned long)dataBufferPos);
      return NO;
    }

    dataBufferPos = 0;
  }

  return YES;
}

@end // @implementation TextOutput
