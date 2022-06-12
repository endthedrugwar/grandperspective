#import <Cocoa/Cocoa.h>

@class NamedFilter;
@class FilterRepository;
@class FilterEditor;
@class FilterPopUpControl;

@interface FilterSelectionPanelControl : NSWindowController {
  IBOutlet NSPopUpButton  *filterPopUp;

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

/* Returns the filter that has been selected.
 */
@property (nonatomic, readonly, strong) NamedFilter *selectedNamedFilter;

@end
