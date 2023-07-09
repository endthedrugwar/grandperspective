#import "FileItemMappingCollection.h"

#import "PlainFileItem.h"
#import "DirectoryItem.h"

#import "StatelessFileItemMapping.h"
#import "UniformTypeMappingScheme.h"
#import "AccessMappingScheme.h"
#import "CreationMappingScheme.h"
#import "ModificationMappingScheme.h"

@interface MappingByLevel : StatelessFileItemMapping
@end

@interface MappingByExtension : StatelessFileItemMapping
@end

@interface MappingByFilename : StatelessFileItemMapping
@end

@interface MappingByDirectoryName : StatelessFileItemMapping
@end

@interface MappingByTopDirectoryName : StatelessFileItemMapping
@end

@implementation MappingByLevel

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  return depth;
}

- (NSUInteger) hashForFileItem:(FileItem *)item inTree:(FileItem *)treeRoot {
  // Establish the depth of the file item in the tree.

  // Matching parent directories as a stop-criterion, as opposed to matching the file items
  // directly. The reason is that when the item is at depth 0, it does not necessarily equal the
  // treeRoot; When package contents are hidden, a stand-in item is used for directory items that
  // are packages.
  
  FileItem  *fileItem = item.parentDirectory;
  FileItem  *itemToMatch = treeRoot.parentDirectory;
  NSUInteger  depth = 0;
  
  while (fileItem != itemToMatch) {
    fileItem = fileItem.parentDirectory;
    depth++;
    
    NSAssert(fileItem != nil, @"Failed to encounter treeRoot");
  }
  
  return depth;
}


- (BOOL) canProvideLegend {
  return YES;
}

//----------------------------------------------------------------------------
// Implementation of informal LegendProvidingFileItemMapping protocol

- (NSString *)descriptionForHash:(NSUInteger)hash {
  if (hash == 0) {
    return NSLocalizedString(@"Outermost level", @"Legend for Level mapping scheme.");
  }
  else {
    NSString  *fmt = NSLocalizedString(@"Level %d", @"Legend for Level mapping scheme.");
    return [NSString stringWithFormat: fmt, hash];
  }
}

- (NSString *)descriptionForRemainingHashes {
  return NSLocalizedString(@"Lower levels", @"Misc. description for Level mapping scheme.");
}

@end // @implementation MappingByLevel


@implementation MappingByExtension

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  return item.systemPathComponent.pathExtension.hash;
}

@end // @implementation MappingByExtension


@implementation MappingByFilename

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  return item.systemPathComponent.hash;
}

@end // @implementation MappingByFilename


@implementation MappingByDirectoryName

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  if (!item.isDirectory) {
    item = item.parentDirectory;
  }

  return item.systemPathComponent.hash;
}

@end // @implementation MappingByDirectoryName 


@implementation MappingByTopDirectoryName

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  while (depth > 1 || (depth == 1 && !item.isDirectory)) {
    item = item.parentDirectory;
    --depth;
  }

  return item.label.hash;
}

- (NSUInteger) hashForFileItem:(FileItem *)item inTree:(FileItem *)treeRoot {
  FileItem  *prev = item;
  while (item != treeRoot) {
    prev = item;
    item = item.parentDirectory;
    NSAssert(item != nil, @"Failed to encounter treeRoot");
  }

  return prev.isDirectory ? prev.label.hash : item.label.hash;
}

@end // @implementation MappingByTopDirectoryName 


@implementation FileItemMappingCollection

+ (FileItemMappingCollection*) defaultFileItemMappingCollection {
  static FileItemMappingCollection  *defaultFileItemMappingCollectionInstance = nil;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    FileItemMappingCollection  *instance = [[[FileItemMappingCollection alloc] init] autorelease];
    
    [instance addFileItemMappingScheme: [[[MappingByTopDirectoryName alloc] init] autorelease]
                                   key: @"top folder"];
    [instance addFileItemMappingScheme: [[[MappingByDirectoryName alloc] init] autorelease]
                                   key: @"folder"];
    [instance addFileItemMappingScheme: [[[MappingByExtension alloc] init] autorelease]
                                   key: @"extension"];
    [instance addFileItemMappingScheme: [[[MappingByFilename alloc] init] autorelease]
                                   key: @"name"];
    [instance addFileItemMappingScheme: [[[MappingByLevel alloc] init] autorelease]
                                   key: @"level"];
    [instance addFileItemMappingScheme: [[[StatelessFileItemMapping alloc] init] autorelease]
                                   key: @"nothing"];
    [instance addFileItemMappingScheme: [[[UniformTypeMappingScheme alloc] init] autorelease]
                                   key: @"uniform type"];
    [instance addFileItemMappingScheme: [[[CreationMappingScheme alloc] init] autorelease]
                                   key: @"creation"];
    [instance addFileItemMappingScheme: [[[ModificationMappingScheme alloc] init] autorelease]
                                   key: @"modification"];
    [instance addFileItemMappingScheme: [[[AccessMappingScheme alloc] init] autorelease]
                                   key: @"access"];
    defaultFileItemMappingCollectionInstance = [instance retain];
  });
  
  return defaultFileItemMappingCollectionInstance;
}

// Overrides super's designated initialiser.
- (instancetype) init {
  return [self initWithDictionary: [NSMutableDictionary dictionaryWithCapacity: 8]];
}

- (instancetype) initWithDictionary:(NSMutableDictionary *)dictionary {
  if (self = [super init]) {
    schemesDictionary = [dictionary retain];
  }
  return self;
}

- (void) dealloc {
  [schemesDictionary release];
  
  [super dealloc];
}

- (void) addFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)scheme
                              key:(NSString *)key {
  schemesDictionary[key] = scheme;
}

- (void) removeFileItemMappingSchemeForKey:(NSString *)key {
  [schemesDictionary removeObjectForKey: key];
}

- (NSArray *)allKeys {
  return schemesDictionary.allKeys;
}

- (NSObject <FileItemMappingScheme> *)fileItemMappingSchemeForKey:(NSString *)key {
  return schemesDictionary[key];
}

@end // @implementation FileItemMappingCollection
