#import "TreeWriter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"

#import "ApplicationError.h"

#import "TreeVisitingProgressTracker.h"
#import "TextOutput.h"

// Formatting string used in XML (RFC 3339)
NSString  *DateTimeFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

// Localized error messages
#define WRITING_LAST_DATA_FAILED \
NSLocalizedString(@"Failed to write last data to file.", @"Error message")
#define WRITING_BUFFER_FAILED \
NSLocalizedString(@"Failed to write entire buffer.", @"Error message")


@implementation TreeWriter

- (instancetype) init {
  if (self = [super init]) {
    abort = NO;
    error = nil;

    progressTracker = [[TreeVisitingProgressTracker alloc] init];
    textOutput = nil;
  }
  return self;
}

- (void) dealloc {
  [error release];

  [progressTracker release];

  [super dealloc];
}

- (BOOL) writeTree:(AnnotatedTreeContext *)tree toFile:(NSString *)filename options:(id)options {
  NSAssert(!textOutput, @"textOutput not nil");

  textOutput = [[TextOutput alloc] init: filename];
  [progressTracker startingTask];

  [self writeTree: tree options: options];

  if (error==nil && ![textOutput flush]) {
    error = [[ApplicationError alloc] initWithLocalizedDescription: WRITING_LAST_DATA_FAILED];
  }

  [progressTracker finishedTask];

  return (error==nil) && !abort;
}

- (void) writeTree:(AnnotatedTreeContext *)tree options:(id)options {
  NSAssert(NO, @"This method should be overridden.");
}

- (void) abort {
  abort = YES;
}

- (BOOL) aborted {
  return (error==nil) && abort;
}

- (NSError *)error {
  return error;
}

- (NSDictionary *)progressInfo {
  return [progressTracker progressInfo];
}

@end // @implementation TreeWriter


@implementation TreeWriter (ProtectedMethods)

+ (NSDateFormatter *)nsTimeFormatter {
  static NSDateFormatter *timeFmt = nil;
  if (timeFmt == nil) {
    timeFmt = [[NSDateFormatter alloc] init];
    timeFmt.locale = [NSLocale localeWithLocaleIdentifier: @"en_US_POSIX"];
    timeFmt.dateFormat = DateTimeFormat;
    timeFmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
  }
  return timeFmt;
}

+ (NSString *)stringForTime:(CFAbsoluteTime)time {
  if (time == 0) {
    return nil;
  } else {
    return [self.nsTimeFormatter stringFromDate:
            [NSDate dateWithTimeIntervalSinceReferenceDate: time]];
  }
}

- (void) appendString:(NSString *)s {
  if (error != nil) {
    // Don't write anything when an error has occurred.
    //
    // Note: Still keep writing if "only" the abort flag is set. This way, an
    // external "abort" of the write operation still results in valid XML.
    return;
  }

  if (![textOutput appendString: s]) {
    error = [[ApplicationError alloc] initWithLocalizedDescription: WRITING_BUFFER_FAILED];

    abort = YES;
  }
}

- (void) dumpItemContents:(Item *)item {
  if (abort || item == nil) {
    return;
  }

  if (item.isVirtual) {
    [self dumpItemContents: ((CompoundItem *)item).first];
    [self dumpItemContents: ((CompoundItem *)item).second];
  }
  else {
    FileItem  *fileItem = (FileItem *)item;

    if (fileItem.isPhysical) {
      // Only include actual files.

      if (fileItem.isDirectory) {
        [self appendFolderElement: (DirectoryItem *)fileItem];
      }
      else {
        [self appendFileElement: (PlainFileItem *)fileItem];
      }
    }
  }
}

- (void) appendFolderElement:(DirectoryItem *)dirItem {
  NSAssert(NO, @"This method should be overridden.");
}

- (void) appendFileElement:(FileItem *)fileItem {
  NSAssert(NO, @"This method should be overridden.");
}

@end // @implementation TreeWriter (ProtectedMethods)
