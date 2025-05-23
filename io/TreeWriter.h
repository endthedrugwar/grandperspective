#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AnnotatedTreeContext;
@class ProgressTracker;

@class Item;
@class PlainFileItem;
@class DirectoryItem;
@class TextOutput;

// Formatting string used in XML
extern NSString  *DateTimeFormat;

/* Abstract base class for writing a tree to file.
 */
@interface TreeWriter : NSObject {
  BOOL  abort;
  NSError  *error;

  ProgressTracker  *progressTracker;
  TextOutput  *textOutput;
}

/* Writes the tree to file. Returns YES if the operation completed successfully. Returns NO if an
 * error occurred, or if the operation has been aborted. In the latter case the file will still be
 * valid. It simply will not contain all files/folders in the tree.
 */
- (BOOL) writeTree:(AnnotatedTreeContext *)tree toFile:(NSURL *)path options:(id)options;

/* Abstract method that should write the tree via repeated invocations of appendString:.
 */
- (void) writeTree:(AnnotatedTreeContext *)tree options:(id)options;

/* Aborts writing (when it is carried out in a different execution thread).
 */
- (void) abort;

/* Returns YES iff the writing task was aborted externally (i.e. using -abort).
 */
@property (nonatomic, readonly) BOOL aborted;

/* Returns details of the error iff there was an error when carrying out the writing task.
 */
@property (nonatomic, readonly, copy, nullable) NSError *error;

/* Returns a dictionary containing information about the progress of the ongoing tree-writing task.
 *
 * It can safely be invoked from a different thread than the one that invoked -writeTree:toFile:
 * (and not doing so would actually be quite silly).
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

@end

@interface TreeWriter (ProtectedMethods)

/* Formatter used to create (locale-independent) string representations for time values. Has same
 * format as timeFormatter.
 */
@property (class, nonatomic, readonly) NSDateFormatter *nsTimeFormatter;

+ (nullable NSString *)stringForTime:(CFAbsoluteTime)time;

- (TextOutput *)createTextOutput:(NSURL *)path;

- (void) appendString:(NSString *)s;

/* Dumps the contents of the given item by invoking appendFileElement: and appendFolderElement: as
 * needed on all its children.
 */
- (void) dumpItemContents:(Item *)item;

/* Abstract method to append details of a given folder. It should invoke dumpItemContents to
 * dump the contents.
 */
- (void) appendFolderElement:(DirectoryItem *)dirItem;

/* Abstract method to append details of a given file.
 */
- (void) appendFileElement:(PlainFileItem *)fileItem;

@end

NS_ASSUME_NONNULL_END
