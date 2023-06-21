#import <Cocoa/Cocoa.h>

#import "FileItem.h"

@class UniformType;

/* Represents a plain file that, unlike a directory, may have a type associated with it.
 */
@interface PlainFileItem : FileItem {
}

- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(item_size_t)size
                          type:(UniformType *)type
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) UniformType *uniformType;

@end
