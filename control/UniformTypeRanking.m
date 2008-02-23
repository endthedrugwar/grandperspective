#import "UniformTypeRanking.h"

#import "UniformType.h"
#import "UniformTypeInventory.h"


NSString  *UniformTypesRankingKey = @"uniformTypesRanking";

@interface UniformTypeRanking (PrivateMethods) 

- (void) uniformTypeAdded: (NSNotification *)notification;

@end


@implementation UniformTypeRanking

+ (UniformTypeRanking *)defaultUniformTypeRanking {
  static UniformTypeRanking
    *defaultUniformTypeRankingInstance = nil;

  if (defaultUniformTypeRankingInstance==nil) {
    defaultUniformTypeRankingInstance = [[UniformTypeRanking alloc] init];
  }
  
  return defaultUniformTypeRankingInstance;
}


- (id) init {
  if (self = [super init]) {
    rankedTypes = [[NSMutableArray alloc] initWithCapacity: 32];
  }
  
  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [rankedTypes release];
  
  [super dealloc];
}


- (void) loadRanking: (UniformTypeInventory *)typeInventory {
  NSAssert([rankedTypes count] == 0, @"List must be empty before load.");
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];  
  NSArray  *rankedUTIs = [userDefaults arrayForKey: UniformTypesRankingKey];
  
  NSEnumerator  *utiEnum = [rankedUTIs objectEnumerator];
  NSString  *uti;
  while (uti = [utiEnum nextObject]) {
    UniformType  *type = [typeInventory uniformTypeForIdentifier: uti];
    
    if (type != nil) {
      // Only add the type if a UniformType instance was created successfully.
      [rankedTypes addObject: type];
    }
  }
  
  NSLog(@"Loaded %d types from preferences (%d discarded)", 
           [rankedTypes count], [rankedUTIs count] - [rankedTypes count]);
}

- (void) storeRanking {
  NSMutableArray  *rankedUTIs =
    [[NSMutableArray alloc] initWithCapacity: [rankedTypes count]];
    
  NSMutableSet  *encountered = 
    [NSMutableSet setWithCapacity: [rankedUTIs count]];
    
  NSEnumerator  *typeEnum = [rankedTypes objectEnumerator];
  UniformType  *type;
  while (type = [typeEnum nextObject]) {
    NSString  *uti = [type uniformTypeIdentifier];
    
    if (! [encountered containsObject: uti]) {
      // Should the ranked list contain duplicate UTIs, only add the first.
      [encountered addObject: uti];
     
      [rankedUTIs addObject: uti];
    }
  }
  
  NSUserDefaults  *userDefaults = [NSUserDefaults standardUserDefaults];
  
  [userDefaults setObject: rankedUTIs forKey: UniformTypesRankingKey];
  
  NSLog(@"Stored %d types to preferences (%d discarded)", 
           [rankedUTIs count], [rankedTypes count] - [rankedUTIs count]);
}


- (void) observeUniformTypeInventory: (UniformTypeInventory *)typeInventory {
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [nc addObserver: self selector: @selector(uniformTypeAdded:)
        name: UniformTypeAddedEvent object: typeInventory];
}


- (NSArray *) uniformTypeRanking {
  // Return an immutable copy of the array.
  return [NSArray arrayWithArray: rankedTypes];  
}

- (void) updateUniformTypeRanking: (NSArray *)ranking {
  // Updates the ranking while keeping new types that may have appeared in the
  // meantime.
  [rankedTypes replaceObjectsInRange: NSMakeRange(0, [ranking count])
                 withObjectsFromArray: ranking];
}

@end // @implementation UniformTypeRanking


@implementation UniformTypeRanking (PrivateMethods) 

- (void) uniformTypeAdded: (NSNotification *)notification {
  UniformType  *type = [[notification userInfo] objectForKey: UniformTypeKey];

  [rankedTypes addObject: type];

  NSLog(@"uniformTypeAdded: %@", type);
}

@end // @implementation UniformTypeRanking (PrivateMethods) 