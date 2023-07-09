#import <Cocoa/Cocoa.h>

@class FilterRepository;
@class FilterEditor;

@interface FiltersWindowControl : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

  IBOutlet NSButton  *editFilterButton;
  IBOutlet NSButton  *removeFilterButton;

  IBOutlet NSTableView  *filterView;
  
  FilterRepository  *filterRepository;
  
  FilterEditor  *filterEditor;
  
  // The data in the table view (names of the filters as NSString)
  NSMutableArray  *filterNames;

  // Non-localized name of filter to select.
  NSString  *filterNameToSelect;
}

// Override designated initialisers
- (instancetype) initWithWindow:(NSWindow *)window NS_UNAVAILABLE;
- (instancetype) initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype) init;
- (instancetype) initWithFilterRepository:(FilterRepository *)filterRepository NS_DESIGNATED_INITIALIZER;

- (IBAction) okAction:(id)sender;

- (IBAction) addFilterToRepository:(id)sender;
- (IBAction) editFilterInRepository:(id)sender;
- (IBAction) removeFilterFromRepository:(id)sender;

@end // @interface EditFiltersWindowControl
