#import <Cocoa/Cocoa.h>

extern NSString  *SelectedFilterRenamed;
extern NSString  *SelectedFilterRemoved;
extern NSString  *SelectedFilterUpdated;

@class FilterRepository;
@class UniqueTagsTransformer;

/* Controller for a pop-up button for selecting the filters in the filter repository. It observes
 * the repository and updates the button when filters are added, removed or renamed. It also fires
 * events itself when the selected filter is either renamed, removed or updated. Where available,
 * the pop-up shows the localized names of the filters.
 */
@interface FilterPopUpControl : NSObject {
  NSPopUpButton  *popUpButton;
  FilterRepository  *filterRepository;
  UniqueTagsTransformer  *tagMaker;
  
  NSNotificationCenter  *notificationCenter;
}

// Overrides designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithPopUpButton:(NSPopUpButton *)popUpButton;

- (instancetype) initWithPopUpButton:(NSPopUpButton *)popUpButton
                    filterRepository:(FilterRepository *)filterRepository;

- (instancetype) initWithPopUpButton:(NSPopUpButton *)popUpButton
                    filterRepository:(FilterRepository *)filterRepository
                          noneOption:(BOOL)noneOption NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSNotificationCenter *notificationCenter;

/* Returns the locale-independent name of the selected filter.
 */
@property (nonatomic, readonly, copy) NSString *selectedFilterName;

/* Selects the filter with the given locale-independent name.
 */
- (void) selectFilterNamed:(NSString *)name;

@end
