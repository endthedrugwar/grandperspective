#import "UniformTypeMappingScheme.h"

#import "StatefulFileItemMapping.h"
#import "PlainFileItem.h"
#import "UniformType.h"
#import "UniformTypeRanking.h"


@interface UniformTypeMappingScheme (PrivateMethods)

- (void) typeRankingChanged:(NSNotification *)notification;

@end


@interface MappingByUniformType : StatefulFileItemMapping {

  // Cache mapping UTIs (NSString) to integer values (NSNumber)
  NSMutableDictionary  *hashForUTICache;
  
  NSArray  *orderedTypes;
}

@end


@implementation UniformTypeMappingScheme

- (instancetype) init {
  return [self initWithUniformTypeRanking: UniformTypeRanking.defaultUniformTypeRanking];

}

- (instancetype) initWithUniformTypeRanking: (UniformTypeRanking *)typeRanking {
  if (self = [super init]) {
    _uniformTypeRanking = [typeRanking retain];
    
    NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;

    [nc addObserver: self
           selector: @selector(typeRankingChanged:)
               name: UniformTypeRankingChangedEvent
             object: typeRanking];
  }
  
  return self;
}

- (void) dealloc {
  [NSNotificationCenter.defaultCenter removeObserver: self];
  
  [_uniformTypeRanking release];
  
  [super dealloc];
}


//----------------------------------------------------------------------------
// Implementation of FileItemMappingScheme protocol

- (NSObject <FileItemMapping> *)fileItemMappingForTree:(DirectoryItem *)tree {
  return [[[MappingByUniformType alloc] initWithFileItemMappingScheme: self] autorelease];
}

@end // @implementation UniformTypeMappingScheme


@implementation UniformTypeMappingScheme (PrivateMethods)

- (void) typeRankingChanged: (NSNotification *)notification {
  NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;
  
  [nc postNotificationName: MappingSchemeChangedEvent object: self];
}

@end // @implementation UniformTypeMappingScheme (PrivateMethods)


@implementation MappingByUniformType

- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)schemeVal {

  if (self = [super initWithFileItemMappingScheme: schemeVal]) {
    hashForUTICache = [[NSMutableDictionary dictionaryWithCapacity: 16] retain];
    
    UniformTypeRanking  *typeRanking = ((UniformTypeMappingScheme *)schemeVal).uniformTypeRanking;
    
    orderedTypes = [typeRanking.undominatedRankedUniformTypes retain];
  }
  
  return self;
}

- (void) dealloc {
  [hashForUTICache release];

  [orderedTypes release];
  
  [super dealloc];
}


//----------------------------------------------------------------------------
// Implementation of FileItemMapping protocol

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  UniformType  *type = item.isDirectory ? nil : ((PlainFileItem *)item).uniformType;
  
  if (type == nil) {
    // Unknown type
    return NSIntegerMax;
  }
  
  NSString  *uti = type.uniformTypeIdentifier;
  NSNumber  *hash = hashForUTICache[uti];
  if (hash != nil) {
    return hash.intValue;
  }
    
  NSSet  *ancestorTypes = type.ancestorTypes;
  NSUInteger  utiIndex = 0;
  
  while (utiIndex < orderedTypes.count) {
    UniformType  *orderedType = orderedTypes[utiIndex];
  
    if (type == orderedType || [ancestorTypes containsObject: orderedType]) {
      // Found the first type in the list that the file item conforms to.
      
      // Add it to the cache for next time.
      hashForUTICache[uti] = @(utiIndex);
      return utiIndex;
    }
    
    utiIndex++;
  }
  
  NSAssert(NO, @"No conforming type found.");
  return 0;
}


- (BOOL) canProvideLegend {
  return YES;
}

//----------------------------------------------------------------------------
// Implementation of informal LegendProvidingFileItemMapping protocol

- (NSString *)descriptionForHash:(NSUInteger)hash {
  if (hash >= orderedTypes.count) {
    return nil;
  }
  
  UniformType  *type = orderedTypes[hash];
  
  NSString  *descr = type.description;
   
  return (descr != nil) ? descr : type.uniformTypeIdentifier;
}

- (NSString *)descriptionForRemainingHashes {
  return NSLocalizedString(@"other file types",
                           @"Misc. description for File type mapping scheme.");
}

@end
