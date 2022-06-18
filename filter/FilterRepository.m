#import "FilterRepository.h"

#import "Filter.h"

#import "NotifyingDictionary.h"


// The key for storing user filters
NSString  *UserFiltersKey = @"filters";

// The key for storing application-provided tests
NSString  *AppFiltersKey = @"GPDefaultFilters";


@interface FilterRepository (PrivateMethods)

/* Add filters as extracted from a property or user preferences file to the given dictionary.
 */
- (void) addStoredFilters:(NSDictionary *)storedFilters
            toLiveFilters:(NSMutableDictionary *)liveFilters;

@end // @interface FilterRepository (PrivateMethods)


@implementation FilterRepository

+ (FilterRepository *)defaultFilterRepository {
  static FilterRepository  *defaultInstance = nil;

  if (defaultInstance == nil) {
    defaultInstance = [[FilterRepository alloc] init];
  }
  
  return defaultInstance;
}


- (instancetype) init {
  if (self = [super init]) {
    NSMutableDictionary  *initialFilterDictionary =
      [NSMutableDictionary dictionaryWithCapacity: 16];
    
    // Load application-provided filters from the information properties file.
    [self addStoredFilters: [NSBundle.mainBundle objectForInfoDictionaryKey: AppFiltersKey]
             toLiveFilters: initialFilterDictionary];
    applicationProvidedFilters = [[NSDictionary alloc] initWithDictionary: initialFilterDictionary];

    // Load additional user-created tests from preferences.
    [self addStoredFilters: [NSUserDefaults.standardUserDefaults dictionaryForKey: UserFiltersKey]
             toLiveFilters: initialFilterDictionary];

    // Store filters in a NotifyingDictionary
    _filtersByName =
      (NSDictionary *)[[NotifyingDictionary alloc] initWithCapacity: 16
                                                    initialContents: initialFilterDictionary];
  }
  
  return self;
}

- (void) dealloc {
  [_filtersByName release];
  [applicationProvidedFilters release];

  [super dealloc];
}


- (NotifyingDictionary *)filtersByNameAsNotifyingDictionary {
  return (NotifyingDictionary *)self.filtersByName;
}


- (Filter *)filterForName:(NSString *)name {
  return self.filtersByName[name];
}

- (Filter *)applicationProvidedFilterForName:(NSString *)name {
  return applicationProvidedFilters[name];
}


- (void) storeUserCreatedFilters {
  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;
  
  NSMutableDictionary  *filtersDict = 
    [NSMutableDictionary dictionaryWithCapacity: self.filtersByName.count];


  for (NSString *name in [self.filtersByName keyEnumerator]) {
    Filter  *filter = self.filtersByName[name];

    if (filter != applicationProvidedFilters[name]) {
      filtersDict[name] = [filter dictionaryForObject];
    }
  }

  [userDefaults setObject: filtersDict forKey: UserFiltersKey];
  
  [userDefaults synchronize];
}

@end // @implementation FilterTestRepository


@implementation FilterRepository (PrivateMethods) 

- (void) addStoredFilters:(NSDictionary *)storedFilters
            toLiveFilters:(NSMutableDictionary *)liveFilters {
  for (NSString *name in [storedFilters keyEnumerator]) {
    NSDictionary  *storedFilter = storedFilters[name];
    Filter  *filter = [Filter filterFromDictionary: storedFilter];
    
    liveFilters[name] = filter;
  }
}

@end // @implementation FilterRepository (PrivateMethods) 
