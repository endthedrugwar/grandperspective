#import <Foundation/Foundation.h>

@interface InputStreamAdapter : NSInputStream<NSStreamDelegate> {

  NSInputStream*  inputStream;

  BOOL  inputDataAvailable;
  BOOL  inputEndEncountered;

  NSCondition  *condition;
}

- (instancetype) initWithInputStream:(NSInputStream *)inputStream;

- (void) open;
- (void) close;

// Stream event handler
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode;

@end
