#import <Cocoa/Cocoa.h>

@class NamedFilter;
@class FilterRepository;
@class FilterEditor;
@class FilterPopUpControl;

@interface FilterSelectionPanelControl : NSWindowController {
  IBOutlet NSPopUpButton  *filterPopUp;
  IBOutlet NSButton  *applyDefaultFilterCheckbox;

  FilterRepository  *filterRepository;

  FilterEditor  *filterEditor;
  FilterPopUpControl  *filterPopUpControl;
}

// Override designated initialisers
- (instancetype) initWithWindow:(NSWindow *)window NS_UNAVAILABLE;
- (instancetype) initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype) init;
- (instancetype) initWithFilterRepository:(FilterRepository *)filterRepository NS_DESIGNATED_INITIALIZER;

- (IBAction) editFilter:(id)sender;
- (IBAction) addFilter:(id)sender;

- (IBAction) okAction:(id)sender;
- (IBAction) cancelAction:(id)sender;

- (void) selectFilterNamed:(NSString *)name;

/* Specifies if the user should be able to choose if the default filter is applied as well. It
 * should only be enabled when 1) there is a default filter, and 2) the user initiates a new scan
 * (instead of applying a filter to an existing view).
 */
- (void) enableApplyDefaultFilterOption:(BOOL)enable;

/* Returns the filter that has been selected.
 */
@property (nonatomic, readonly, strong) NamedFilter *selectedNamedFilter;

/* Returns if the default filter should be applied (next to the selected filter)
 */
@property (nonatomic, readonly) BOOL applyDefaultFilter;

@end
