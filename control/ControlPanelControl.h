#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class ColorLegendTableViewControl;
@class ColorListCollection;
@class DirectoryItem;
@class DirectoryViewControl;
@class DirectoryViewDisplaySettings;
@class FileItemMappingCollection;
@class FilterPopUpControl;
@class FilterRepository;
@class ItemInFocusControls;
@class TreeDrawerSettings;

extern NSString  *CommentsChangedEvent;
extern NSString  *DisplaySettingsChangedEvent;

@interface ControlPanelControl : NSWindowController {
  IBOutlet NSTabView  *tabView;

  // "Display" panel
  IBOutlet NSPopUpButton  *colorMappingPopUp;
  IBOutlet NSPopUpButton  *colorPalettePopUp;
  IBOutlet NSPopUpButton  *maskPopUp;
  IBOutlet NSTableView  *colorLegendTable;
  IBOutlet NSButton  *maskCheckBox;
  IBOutlet NSButton  *showEntireVolumeCheckBox;
  IBOutlet NSButton  *showPackageContentsCheckBox;

  // "Info" panel
  IBOutlet NSImageView  *volumeIconView;
  IBOutlet NSTextField  *volumeNameField;
  IBOutlet NSTextView  *scanPathTextView;
  IBOutlet NSTextField  *filterNameField;
  IBOutlet NSTextView  *commentsTextView;
  IBOutlet NSTextField  *scanTimeField;
  IBOutlet NSTextField  *fileSizeMeasureField;
  IBOutlet NSTextField  *volumeSizeField;
  IBOutlet NSTextField  *miscUsedSpaceField;
  IBOutlet NSTextField  *treeSizeField;
  IBOutlet NSTextField  *freeSpaceField;
  IBOutlet NSTextField  *freedSpaceField;
  IBOutlet NSTextField  *numScannedFilesField;
  IBOutlet NSTextField  *numDeletedFilesField;

  // "Focus" panel
  IBOutlet NSTextField  *visibleFolderTitleField;
  IBOutlet NSTextView  *visibleFolderPathTextView;
  IBOutlet NSTextField  *visibleFolderExactSizeField;
  IBOutlet NSTextField  *visibleFolderSizeField;

  IBOutlet NSTextField  *selectedItemTitleField;
  IBOutlet NSTextView  *selectedItemPathTextView;
  IBOutlet NSTextField  *selectedItemExactSizeField;
  IBOutlet NSTextField  *selectedItemSizeField;

  IBOutlet NSTextField  *selectedItemTypeIdentifierField;

  IBOutlet NSTextField  *selectedItemCreationTimeField;
  IBOutlet NSTextField  *selectedItemModificationTimeField;
  IBOutlet NSTextField  *selectedItemAccessTimeField;

  // Other fields

  ItemInFocusControls  *visibleFolderFocusControls;
  ItemInFocusControls  *selectedItemFocusControls;

  FileItemMappingCollection  *colorMappings;
  ColorListCollection  *colorPalettes;
  ColorLegendTableViewControl  *colorLegendControl;

  FilterPopUpControl  *maskPopUpControl;
  FilterRepository  *filterRepository;

  DirectoryViewControl  *observedDirectoryView;
}

@property (class, nonatomic, readonly) ControlPanelControl *singletonInstance;

// Changes to display settings that require special handling.
- (IBAction) maskChanged:(id)sender;
- (IBAction) showPackageContentsCheckBoxChanged:(id)sender;

// Invoked when a display setting is changed that does not require special handling by the control
- (IBAction) displaySettingChanged:(id)sender;

- (void) mainWindowChanged:(nullable id)sender;

@property (nonatomic, readonly) BOOL isPanelShown;

- (void) showPanel;
- (void) hidePanel;

// Ensures the panel is shown (and in front) with the info panel visible.
- (void) showInfoPanel;


// Returns the current display settings. This is always a new instance.
- (DirectoryViewDisplaySettings *)displaySettings;

// Returns the comments in the Info panel (which the user can modify)
- (NSString *)comments;

// Converts a description of the display settings to an object that realizes these.
//
// Note: The mapping is not fully one-to-one, as both classes serve a different purpose.
// - DirectoryViewDisplaySettings captures the display settings that can be changed from the
//   control panel.
// - TreeDrawerSettings are the settings that the tree drawer needs
//
// More specifically, the differences are:
// - The showEntireVolume setting is not part of TreeDrawerSettings, as this is realized by
//   invoking the drawer with a different tree
// - The maxDrawDepth settings it not part of DirectoryViewDisplaySettings, as it is changed from
//   the toolbar, given that changing it is closely related to the selection focus depth (and uses
//   the same buttons)
- (TreeDrawerSettings *)instantiateDisplaySettings:(DirectoryViewDisplaySettings *)displaySettings
                                           forTree:(DirectoryItem *)tree
                                      displayDepth:(unsigned)displayDepth;

@end

NS_ASSUME_NONNULL_END
