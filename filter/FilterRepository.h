#import <Cocoa/Cocoa.h>

@class NotifyingDictionary;
@class Filter;

extern NSString  *NoneFilter;


@interface FilterRepository : NSObject {
  // Contains the filters provided by the application.
  NSDictionary  *applicationProvidedFilters;
}

@property (class, nonatomic, readonly) FilterRepository *defaultFilterRepository;

/* Returns dictionary which can subsequently be modified.
 */
@property (nonatomic, readonly, strong) NotifyingDictionary *filtersByNameAsNotifyingDictionary;

/* Returns dictionary as an NSDictionary, which is useful if the dictionary does not need to be
 * modified. Note, the dictionary can still be modified by casting it to NotifyingDictionary. This
 * is only a convenience method.
 */
@property (nonatomic, readonly, copy) NSDictionary *filtersByName;

- (Filter *)filterForName:(NSString *)name;

- (Filter *)applicationProvidedFilterForName:(NSString *)name;

- (void) storeUserCreatedFilters;

@end
