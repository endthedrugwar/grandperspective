#import "ColorLegendTableViewControl.h"

#import "DirectoryView.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"

#import "FileItem.h"
#import "FileItemMapping.h"

#import "GradientRectangleDrawer.h"
#import "TreeDrawerSettings.h"


NSString  *ColorImageColumnIdentifier = @"colorImage";
NSString  *ColorDescriptionColumnIdentifier = @"colorDescription";


@interface ColorLegendTableViewControl (PrivateMethods)

//----
// Partial implementation of NSTableDataSource interface
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView;
- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column
             row:(int)row;
//---- 

- (NSString *)descriptionForRow:(NSUInteger)row;

- (void) makeColorImages;
- (void) updateDescriptionColumnWidth;
- (void) updateSelectedRow;

- (void) colorPaletteChanged:(NSNotification *)notification;
- (void) colorMappingChanged:(NSNotification *)notification;
- (void) selectedItemChanged:(NSNotification *)notification;
- (void) visibleTreeChanged:(NSNotification *)notification;

@end


@implementation ColorLegendTableViewControl

- (instancetype) initWithDirectoryView:(DirectoryView *)dirViewVal
                             tableView:(NSTableView *)tableViewVal {
  if (self = [super init]) {
    dirView = [dirViewVal retain];
    tableView = [tableViewVal retain];
    
    NSArray  *columns = tableView.tableColumns;
    
    NSTableColumn  *imageColumn = columns[0];
    imageColumn.identifier = ColorImageColumnIdentifier;
    [imageColumn setEditable: NO];

    NSImageCell  *imageCell = [[[NSImageCell alloc] initImageCell: nil] autorelease];
    imageColumn.dataCell = imageCell;
    
    NSTableColumn  *descrColumn = columns[1];
    descrColumn.identifier = ColorDescriptionColumnIdentifier;
    [descrColumn setEditable: NO];
    
    colorImages = nil;
    [self makeColorImages];
    [self updateDescriptionColumnWidth];
    
    tableView.dataSource = self;

    NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;
    [nc addObserver: self
           selector: @selector(colorPaletteChanged:)
               name: ColorPaletteChangedEvent
             object: dirView];
    [nc addObserver: self
           selector: @selector(colorMappingChanged:)
               name: ColorMappingChangedEvent
             object: dirView];
    [nc addObserver: self
           selector: @selector(selectedItemChanged:)
               name: SelectedItemChangedEvent
             object: dirView.pathModelView];
    [nc addObserver: self
           selector: @selector(visibleTreeChanged:)
               name: VisibleTreeChangedEvent
             object: dirView.pathModelView];
  }
  
  return self;
}

- (void) dealloc {
  [NSNotificationCenter.defaultCenter removeObserver: self];
  
  [dirView release];
  [tableView release];
  [colorImages release];
  
  [super dealloc];
}

@end // @implementation ColorLegendTableViewControl


@implementation ColorLegendTableViewControl (PrivateMethods)

//-----------------------------------------------------------------------------
// Partial implementation of NSTableDataSource interface

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return colorImages.count;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column
             row:(int)row {
  if (column.identifier == ColorImageColumnIdentifier) {
    return colorImages[row];
  }
  else if (column.identifier == ColorDescriptionColumnIdentifier) {
    return [self descriptionForRow: row];
  }
  else {
    NSAssert(NO, @"Unexpected column.");
    return nil;
  }
}


//-----------------------------------------------------------------------------

- (NSString *)descriptionForRow:(NSUInteger)row {
  NSObject <FileItemMapping>  *colorMapper = [[dirView treeDrawerSettings] colorMapper];

  if (colorMapper.canProvideLegend) {
    LegendProvidingFileItemMapping  *legendProvider = (LegendProvidingFileItemMapping *)colorMapper;
  
    if (row < colorImages.count - 1) {
      return [legendProvider descriptionForHash: row];
    }
    else {
      if ([legendProvider descriptionForHash: row + 1] != nil) {
        return legendProvider.descriptionForRemainingHashes;
      }
      else {
        return [legendProvider descriptionForHash: row];
      }
    }
  }
  else {
    return nil;
  }
}


- (void) makeColorImages {
  NSColorList  *colorPalette = dirView.treeDrawerSettings.colorPalette;
  GradientRectangleDrawer  *drawer = 
    [[[GradientRectangleDrawer alloc] initWithColorPalette: colorPalette] autorelease];
  
  NSUInteger  numColors = colorPalette.allKeys.count;
  [colorImages release];
  colorImages = [[NSMutableArray alloc] initWithCapacity: numColors];

  NSTableColumn  *imageColumn = [tableView tableColumnWithIdentifier: ColorImageColumnIdentifier];
  NSRect  bounds = NSMakeRect(0, 0, imageColumn.width, tableView.rowHeight);

  if (bounds.size.width > 0 && bounds.size.height > 0) {
    int  i = 0;
    while (i < numColors) {
      [colorImages addObject: [drawer drawImageOfGradientRectangleWithColor: i inRect: bounds]];
      i++;
    }
  }
}

- (void) updateDescriptionColumnWidth {
  NSTableColumn  *descrColumn =
    [tableView tableColumnWithIdentifier: ColorDescriptionColumnIdentifier];
  NSCell  *dataCell = descrColumn.dataCell;
  
  // TODO: Determine if more attributes need to be provided for sizeWithAttributes: to always return
  // the right width. So far, it appears as if the font is all that is needed.
  NSDictionary  *attribs = 
    [[[NSDictionary alloc] initWithObjectsAndKeys: dataCell.font, NSFontAttributeName, nil]
     autorelease];

  NSUInteger  numColors = colorImages.count;
  NSUInteger  i = 0;
  float  maxWidth = 0;
  while (i < numColors) {
    NSString  *descr = [self descriptionForRow: i];

    if (descr != nil) {
      float  width = [descr sizeWithAttributes: attribs].width;
    
      if (width > maxWidth) {
        maxWidth = width;
      }
    }
    
    i++;
  }
  
  // Increase for the space at the right and left.
  // TODO: Is there a way to get the exact value dynamically?
  maxWidth += 6;
  
  descrColumn.maxWidth = maxWidth;
  descrColumn.width = maxWidth;
}


/* Update the selected row in the color legend table. When the selected item is a plain file, its
 * color is selected. Otherwise, the selection is cleared.
 */
- (void) updateSelectedRow {
  FileItem  *selectedItem = dirView.pathModelView.selectedFileItem;

  BOOL  rowSelected = NO;

  if (selectedItem != nil && selectedItem.isPhysical) {
    NSObject <FileItemMapping>  *colorMapper = dirView.treeDrawerSettings.colorMapper;

    if (colorMapper.canProvideLegend) {
      NSUInteger  colorIndex = [colorMapper hashForFileItem: selectedItem
                                                     inTree: dirView.treeInView];
      NSUInteger  row = MIN(colorIndex, tableView.numberOfRows - 1);
      
      [tableView selectRowIndexes: [NSIndexSet indexSetWithIndex: row]
             byExtendingSelection: NO];
      rowSelected = YES;
    }
  }
  if ( !rowSelected ) {
    [tableView deselectAll: self];
  }
}


- (void) colorPaletteChanged:(NSNotification *)notification {
  [self makeColorImages];

  // As the number of colors may have changed, the longest description may have changed as well.
  [self updateDescriptionColumnWidth];

  [tableView reloadData];

  [self updateSelectedRow];
}

- (void) colorMappingChanged:(NSNotification *)notification {
  [self updateDescriptionColumnWidth];
  [tableView reloadData];

  [self updateSelectedRow];
}

- (void) selectedItemChanged:(NSNotification *)notification {
  [self updateSelectedRow];
}


- (void) visibleTreeChanged:(NSNotification *)notification {
  // A change of the visible tree changes the level of the selected file item, which may affect its
  // color.
  [self updateSelectedRow];
}

@end // @implementation ColorLegendTableViewControl (PrivateMethods)
