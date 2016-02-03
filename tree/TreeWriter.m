#import "TreeWriter.h"

#import "DirectoryItem.h"
#import "CompoundItem.h"

#import "TreeContext.h"
#import "AnnotatedTreeContext.h"

#import "FilterTestRef.h"
#import "Filter.h"
#import "NamedFilter.h"
#import "FilterSet.h"

#import "ProgressTracker.h"

#import "ApplicationError.h"


#define  BUFFER_SIZE  4096

NSString  *TreeWriterFormatVersion = @"5";

// XML elements
NSString  *ScanDumpElem = @"GrandPerspectiveScanDump";
NSString  *ScanInfoElem = @"ScanInfo";
NSString  *ScanCommentsElem = @"ScanComments";
NSString  *FilterSetElem = @"FilterSet";
NSString  *FilterElem = @"Filter";
NSString  *FilterTestElem = @"FilterTest";
NSString  *FolderElem = @"Folder";
NSString  *FileElem = @"File";

// XML attributes of GrandPerspectiveScanDump
NSString  *AppVersionAttr = @"appVersion";
NSString  *FormatVersionAttr = @"formatVersion";

// XML attributes of GrandPerspectiveScanInfo
NSString  *VolumePathAttr = @"volumePath";
NSString  *VolumeSizeAttr = @"volumeSize";
NSString  *FreeSpaceAttr = @"freeSpace";
NSString  *ScanTimeAttr = @"scanTime";
NSString  *FileSizeMeasureAttr = @"fileSizeMeasure";

// XML attributes of FilterTest
NSString  *InvertedAttr = @"inverted";

// XML attributes of Folder and File
NSString  *NameAttr = @"name";
NSString  *FlagsAttr = @"flags";
NSString  *SizeAttr = @"size";
NSString  *CreatedAttr = @"created";
NSString  *ModifiedAttr = @"modified";
NSString  *AccessedAttr = @"accessed";

// XML attribute values
NSString  *TrueValue = @"true";
NSString  *FalseValue = @"false";

// Formatting string used in XML (RFC 3339)
NSString  *DateTimeFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";

// Localized error messages
#define WRITING_LAST_DATA_FAILED \
   NSLocalizedString(@"Failed to write last data to file.", @"Error message")
#define WRITING_BUFFER_FAILED \
   NSLocalizedString(@"Failed to write entire buffer.", @"Error message")


#define  CHAR_AMPERSAND     0x01
#define  CHAR_LESSTHAN      0x02
#define  CHAR_DOUBLEQUOTE   0x04
#define  CHAR_WHITESPACE    0x08
// All non-printing ASCII characters (this excludes whitespace)
#define  CHAR_NON_PRINTING  0x10

#define  ATTRIBUTE_ESCAPE_CHARS  (CHAR_AMPERSAND | CHAR_LESSTHAN \
                                  | CHAR_DOUBLEQUOTE | CHAR_WHITESPACE \
                                  | CHAR_NON_PRINTING)
#define  CHARDATA_ESCAPE_CHARS   (CHAR_AMPERSAND | CHAR_LESSTHAN \
                                  | CHAR_NON_PRINTING)


/* Escapes the string so that it can be used a valid XML attribute value or
 * valid XML character data. The characters that are escaped are specified by
 * a mask, which must reflect the context where the string is to be used.
 */
NSString *escapedXML(NSString *s, int escapeCharMask) {
  // Lazily construct buffer. Only use it when needed.
  NSMutableString  *buf = nil;
  
  int  i;
  int  numCharsInVal = [s length];
  int  numCharsInBuf = 0;
  
  for (i = 0; i < numCharsInVal; i++) {
    unichar  c = [s characterAtIndex: i];
    NSString  *r = nil;
    if (c == '&' && (escapeCharMask & CHAR_AMPERSAND)!=0 ) {
      r = @"&amp;";
    }
    else if (c == '<' && (escapeCharMask & CHAR_LESSTHAN)!=0 ) {
      r = @"&lt;";
    }
    else if (c == '"' && (escapeCharMask & CHAR_DOUBLEQUOTE)!=0) {
      r = @"&quot;";
    }
    else if (c < 0x20) {
      if (c == 0x09 || c == 0x0a || c == 0x0d) {
        // White space
        if ((escapeCharMask & CHAR_WHITESPACE) != 0) {
          r = @" ";
        }
      } else {
        if ((escapeCharMask & CHAR_NON_PRINTING) != 0) {
          // Some files can have names with non-printing characters. Just do 
          // something to ensure that the XML data can be loaded correctly. 
          // However, no attempt is made to enable a reversible transformation.
          // If anything, such names should be discouraged, not supported.
          r = @"?";
        }
      }
    }
    if (r != nil) {
      if (buf == nil) {
        buf = [NSMutableString stringWithCapacity: numCharsInVal * 2];
      }

      if (numCharsInBuf < i) {
        // Copy preceding characters that did not require escaping to buffer
        [buf appendString: [s substringWithRange:
                                NSMakeRange(numCharsInBuf,
                                            i - numCharsInBuf)]];
        numCharsInBuf = i;
      }
      
      [buf appendString: r];
      numCharsInBuf++;
    }
  }
  
  if (buf == nil) {
    // String did not contain an characters that needed escaping
    return s;
  }
  
  if (numCharsInBuf < numCharsInVal) {
    // Append final characters to buffer
    [buf appendString: [s substringWithRange: 
                            NSMakeRange(numCharsInBuf,
                                        numCharsInVal - numCharsInBuf)]];
    numCharsInBuf = numCharsInVal;
  }
  
  return buf;
}


@interface TreeWriter (PrivateMethods) 

- (void) appendScanDumpElement: (AnnotatedTreeContext *)tree;
- (void) appendScanInfoElement: (AnnotatedTreeContext *)tree;
- (void) appendScanCommentsElement: (NSString *)comments;
- (void) appendFilterSetElement: (FilterSet *)filterSet;
- (void) appendFilterElement: (NamedFilter *)filter;
- (void) appendFilterTestElement: (FilterTestRef *)filterTest;
- (void) appendFolderElement: (DirectoryItem *)dirItem root: (BOOL) isRoot;
- (void) appendFileElement: (FileItem *)fileItem;

- (void) dumpItemContents: (Item *)item;

- (void) appendString: (NSString *)s;

+ (NSString *)stringForTime: (CFAbsoluteTime) time;

@end


@implementation TreeWriter

- (id) init {
  if (self = [super init]) {
    dataBuffer = malloc(BUFFER_SIZE);

    abort = NO;
    error = nil;
    
    progressTracker = [[ProgressTracker alloc] init];
  }
  return self;
}

- (void) dealloc {
  free(dataBuffer);
  
  [error release];

  [progressTracker release];
  
  [super dealloc];
}


- (BOOL) writeTree: (AnnotatedTreeContext *)tree toFile: (NSString *)filename {
  NSAssert(file == NULL, @"File not NULL");

  [progressTracker startingTask];
  
  file = fopen( [filename UTF8String], "w");
  if (file == NULL) {
    return NO;
  }

  dataBufferPos = 0;

  [self appendString: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
  [self appendScanDumpElement: tree];
  
  if (error==nil && dataBufferPos > 0) {
    // Write remaining characters in buffer
    unsigned  numWritten = fwrite( dataBuffer, 1, dataBufferPos, file );
    
    if (numWritten != dataBufferPos) {
      NSLog(@"Failed to write last data: %d bytes written out of %d.", 
                numWritten, dataBufferPos);

      error = [[ApplicationError alloc] initWithLocalizedDescription: 
                  WRITING_LAST_DATA_FAILED];
    }
  }
  
  fclose(file);
  file = NULL;
  
  [progressTracker finishedTask];
  
  return (error==nil) && !abort;
}

- (void) abort {
  abort = YES;
}

- (BOOL) aborted {
  return (error==nil) && abort;
}

- (NSError *) error {
  return error;
}

- (NSDictionary *) progressInfo {
  return [progressTracker progressInfo];
}


+ (CFDateFormatterRef) timeFormatter {
  static CFDateFormatterRef dateFormatter = NULL;
  
  if (dateFormatter == NULL) {
    // Lazily create formatter
    dateFormatter = CFDateFormatterCreate(kCFAllocatorDefault,
                                          NULL,
                                          kCFDateFormatterNoStyle,
                                          kCFDateFormatterNoStyle);
    // Fix the locale so that output is locale independent.
    // Was originally "en_GB" locale, but in OS X 10.11 this went from
    //   dd/MM/yyyy HH:mm
    // to
    //   dd/MM/yyyy, HH:mm
    // which broke parsing saved scans in some situations and also left out
    // timezone information. We now use a safer representation.
    CFDateFormatterSetFormat(dateFormatter, (CFStringRef)DateTimeFormat);
  }
  
  return dateFormatter;
}

+ (NSDateFormatter *) nsTimeFormatter {
    static NSDateFormatter *timeFmt = nil;
    if (timeFmt == nil) {
        timeFmt = [[NSDateFormatter alloc] init];
        [timeFmt setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [timeFmt setDateFormat:DateTimeFormat];
        [timeFmt setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return timeFmt;
}

@end


@implementation TreeWriter (PrivateMethods) 

- (void) appendScanDumpElement: (AnnotatedTreeContext *)annotatedTree {
  NSString  *appVersion =
    [[[NSBundle mainBundle] infoDictionary] objectForKey: 
                                              @"CFBundleVersion"];

  [self appendString: 
    [NSString stringWithFormat: @"<%@ %@=\"%@\" %@=\"%@\">\n", 
       ScanDumpElem, 
       AppVersionAttr, appVersion, 
       FormatVersionAttr, TreeWriterFormatVersion]];
  
  [self appendScanInfoElement: annotatedTree];
  
  [self appendString: [NSString stringWithFormat: @"</%@>\n", ScanDumpElem]];
}


- (void) appendScanInfoElement: (AnnotatedTreeContext *)annotatedTree {
  TreeContext  *tree = [annotatedTree treeContext];

  [self appendString: 
     [NSString stringWithFormat: 
        @"<%@ %@=\"%@\" %@=\"%qu\" %@=\"%qu\" %@=\"%@\" %@=\"%@\">\n", 
        ScanInfoElem, 
        VolumePathAttr, escapedXML( [[tree volumeTree] name], 
                                    ATTRIBUTE_ESCAPE_CHARS ),
        VolumeSizeAttr, [tree volumeSize],
        FreeSpaceAttr, ([tree freeSpace] + [tree freedSpace]),
        ScanTimeAttr, [[TreeWriter nsTimeFormatter] stringFromDate:[tree scanTime]],
        FileSizeMeasureAttr, [tree fileSizeMeasure]]];
  
  [self appendScanCommentsElement: [annotatedTree comments]];
  [self appendFilterSetElement: [tree filterSet]];
  
  [tree obtainReadLock];
  [self appendFolderElement: [tree scanTree] root: YES];
  [tree releaseReadLock];
  
  [self appendString: [NSString stringWithFormat: @"</%@>\n", ScanInfoElem]];
}


- (void) appendScanCommentsElement: (NSString *)comments {
  if ([comments length] == 0) {
    return;
  }

  [self appendString: 
     [NSString stringWithFormat: @"<%@>%@</%@>\n",
        ScanCommentsElem,
        escapedXML(comments, CHARDATA_ESCAPE_CHARS),
        ScanCommentsElem]];
}


- (void) appendFilterSetElement: (FilterSet *)filterSet {
  if ([filterSet numFilters] == 0) {
    return;
  }
  
  [self appendString: [NSString stringWithFormat: @"<%@>\n", FilterSetElem]];

  NSEnumerator  *filterEnum = [[filterSet filters] objectEnumerator];
  NamedFilter  *namedFilter;
  while (namedFilter = [filterEnum nextObject]) {
    [self appendFilterElement: namedFilter];
  }

  [self appendString: [NSString stringWithFormat: @"</%@>\n", FilterSetElem]];
}


- (void) appendFilterElement:(NamedFilter *)namedFilter {
  Filter  *filter = [namedFilter filter];
  if ([filter numFilterTests] == 0) {
    return;
  }
  
  NSString  *nameVal = escapedXML([namedFilter name], ATTRIBUTE_ESCAPE_CHARS);
  NSString  *openElem = [NSString stringWithFormat: @"<%@ %@=\"%@\">\n", 
                           FilterElem,
                           NameAttr, nameVal];
  [self appendString: openElem];

  NSEnumerator  *testEnum = [[filter filterTests] objectEnumerator];
  FilterTestRef  *filterTest;
  while (filterTest = [testEnum nextObject]) {
    [self appendFilterTestElement: filterTest];
  }

  [self appendString: [NSString stringWithFormat: @"</%@>\n", FilterElem]];
}


- (void) appendFilterTestElement: (FilterTestRef *)filterTest {
  NSString  *nameVal = escapedXML([filterTest name], ATTRIBUTE_ESCAPE_CHARS);
  [self appendString: 
          [NSString stringWithFormat: @"<%@ %@=\"%@\" %@=\"%@\" />\n", 
                      FilterTestElem, 
                      NameAttr, nameVal,
                      InvertedAttr,
                      ([filterTest isInverted] ? TrueValue : FalseValue) ]];
}


- (void) appendFolderElement: (DirectoryItem *)dirItem root: (BOOL) isRoot {
  [progressTracker processingFolder: dirItem];

  // For the scan tree root, output the system name so that slashes inside path
  // components can be distinguished from path separators.
  NSString  *rawName = isRoot ? [dirItem systemPathComponent] : [dirItem name];
  NSString  *nameVal = escapedXML(rawName, ATTRIBUTE_ESCAPE_CHARS);
  
  UInt8  flags = [dirItem fileItemFlags];
  NSString  *createdVal = [TreeWriter stringForTime: [dirItem creationTime]];
  NSString  *modifiedVal = [TreeWriter stringForTime: [dirItem modificationTime]];
  NSString  *accessedVal = [TreeWriter stringForTime: [dirItem accessTime]];
  [self appendString: 
   [NSString stringWithFormat: 
               @"<%@ %@=\"%@\"", 
               FolderElem,
               NameAttr, nameVal
    ]];
  if (flags != 0) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%d\"", FlagsAttr, flags]];
  }
  if (createdVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", CreatedAttr, createdVal]];
  }
  if (modifiedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", ModifiedAttr, modifiedVal]];
  }
  if (accessedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", AccessedAttr, accessedVal]];
  }
  [self appendString: @">\n"];  
  
  [self dumpItemContents: [dirItem getContents]];
  
  [self appendString: [NSString stringWithFormat: @"</%@>\n", FolderElem]];
  
  [progressTracker processedFolder: dirItem];
}


- (void) appendFileElement: (FileItem *)fileItem {
  NSString  *nameVal = escapedXML([fileItem name], ATTRIBUTE_ESCAPE_CHARS);
  UInt8  flags = [fileItem fileItemFlags];
  NSString  *createdVal = [TreeWriter stringForTime: [fileItem creationTime]];
  NSString  *modifiedVal = [TreeWriter stringForTime: [fileItem modificationTime]];
  NSString  *accessedVal = [TreeWriter stringForTime: [fileItem accessTime]];
  
  [self appendString: 
   [NSString stringWithFormat:
               @"<%@ %@=\"%@\" %@=\"%qu\"", 
               FileElem,
               NameAttr, nameVal, 
               SizeAttr, [fileItem itemSize]
    ]];
  if (flags != 0) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%d\"", FlagsAttr, flags]];
  }
  if (createdVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", CreatedAttr, createdVal]];
  }
  if (modifiedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", ModifiedAttr, modifiedVal]];
  }
  if (accessedVal != nil) {
    [self appendString: [NSString stringWithFormat: @" %@=\"%@\"", AccessedAttr, accessedVal]];
  }
  [self appendString: @"/>\n"];
}


- (void) dumpItemContents: (Item *)item {
  if (abort) {
    return;
  }
  
  if ([item isVirtual]) {
    [self dumpItemContents: [((CompoundItem *)item) getFirst]];
    [self dumpItemContents: [((CompoundItem *)item) getSecond]];
  }
  else {
    FileItem  *fileItem = (FileItem *)item;
    
    if ([fileItem isPhysical]) {
      // Only include actual files.

      if ([fileItem isDirectory]) {
        [self appendFolderElement: (DirectoryItem *)fileItem root: NO];
      }
      else {
        [self appendFileElement: fileItem];
      }
    }
  }
}


- (void) appendString: (NSString *)s {
  if (error != nil) {
    // Don't write anything when an error has occurred. 
    //
    // Note: Still keep writing if "only" the abort flag is set. This way, an
    // external "abort" of the write operation still results in valid XML.
    return;
  }

  NSData  *newData = [s dataUsingEncoding: NSUTF8StringEncoding];
  const void  *newDataBytes = [newData bytes];
  unsigned  numToAppend = [newData length];
  unsigned  newDataPos = 0;
  
  while (numToAppend > 0) {
    unsigned  numToCopy = ( (dataBufferPos + numToAppend <= BUFFER_SIZE)
                            ? numToAppend 
                            : BUFFER_SIZE - dataBufferPos );

    memcpy( dataBuffer + dataBufferPos, newDataBytes + newDataPos, numToCopy );
    dataBufferPos += numToCopy;
    newDataPos += numToCopy;
    numToAppend -= numToCopy;
    
    if (dataBufferPos == BUFFER_SIZE) {
      unsigned  numWritten = fwrite( dataBuffer, 1, BUFFER_SIZE, file );
      
      if (numWritten != BUFFER_SIZE) {
        NSLog(@"Failed to write entire buffer, %d bytes written", numWritten);
        
        error = [[ApplicationError alloc] initWithLocalizedDescription: 
                    WRITING_BUFFER_FAILED];
        abort = YES;
        
        return; // Do not attempt anymore writes to file.
      }
      
      dataBufferPos = 0;
    }
  }
}


+ (NSString *)stringForTime: (CFAbsoluteTime) time {
  if (time == 0) {
    return nil;
  } else {
    return 
    [(NSString *)CFDateFormatterCreateStringWithAbsoluteTime(NULL,
                                                            [self timeFormatter],
                                                            time)
     autorelease];
  }  
}

@end // @implementation TreeWriter (PrivateMethods) 
