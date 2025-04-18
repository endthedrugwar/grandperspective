#import <Cocoa/Cocoa.h>

@class FilterTestRepository;
@class AnnotatedTreeContext;
@class TreeBalancer;
@class ReadProgressTracker;
@class CompressedInput;

@interface TreeReader : NSObject <NSXMLParserDelegate> {

  FilterTestRepository  *testRepository;

  NSXMLParser  *parser;
  AnnotatedTreeContext  *tree;
  int  formatVersion;

  BOOL  abort;
  NSError  *error;
  
  NSMutableArray  *unboundTests;

  // Parsing datetime strings is slow. There are typically also many duplicate values. Using a
  // cache speeds up parsing by about a factor ten.
  NSMutableDictionary  *timeCache;

  CompressedInput  *decompressor;
  ReadProgressTracker  *progressTracker;
  TreeBalancer  *treeBalancer;

  NSAutoreleasePool  *autoreleasePool;
}

- (instancetype) init;
- (instancetype) initWithFilterTestRepository:(FilterTestRepository *)repository NS_DESIGNATED_INITIALIZER;

/* Reads the tree from a file in scan dump format. Returns the annotated tree context when
 * successful. The tree can then later be retrieved using -annotatedTreeContext. Returns nil if
 * reading is aborted, or if there is an error. In the latter case, the error can be retrieved
 * using -error.
 */
- (AnnotatedTreeContext *)readTreeFromFile:(NSURL *)url;

/* Aborts reading (when it is carried out in a different execution thread). 
 */
- (void) abort;

/* Returns YES iff the reading task was aborted externally (i.e. using -abort).
 */
@property (nonatomic, readonly) BOOL aborted;

/* Returns the tree that was read.
 */
@property (nonatomic, readonly, strong) AnnotatedTreeContext *annotatedTreeContext;

/* Returns details of the error iff there was an error when carrying out the reading task.
 */
@property (nonatomic, readonly, copy) NSError *error;

/* Returns the names of any unbound filter tests, i.e. tests that could not be found in the test
 * repository.
 */
@property (nonatomic, readonly, copy) NSArray *unboundFilterTests;

/* Returns a dictionary containing information about the progress of the ongoing tree-reading task.
 *
 * It can safely be invoked from a different thread than the one that invoked -readTreeFromFile:
 * (and not doing so would actually be quite silly).
 */
@property (nonatomic, readonly, copy) NSDictionary *progressInfo;

@property (nonatomic) int formatVersion;

@end
