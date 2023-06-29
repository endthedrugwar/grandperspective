#import <Cocoa/Cocoa.h>

#import "TreeDrawerSettings.h"

#import "StatelessFileItemMapping.h"
#import "PreferencesPanelControl.h"


@interface TreeDrawerSettings (PrivateMethods)

@property (class, nonatomic, readonly) NSColorList *defaultColorPalette;

@end


@implementation TreeDrawerSettings

// Creates default settings.
- (instancetype) initWithDisplayDepth:(int)displayDepth
                  showPackageContents:(BOOL)showPackageContents {
  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;

  return [self initWithColorMapper: [[[StatelessFileItemMapping alloc] init] autorelease]
                      colorPalette: TreeDrawerSettings.defaultColorPalette
                     colorGradient: [userDefaults floatForKey: DefaultColorGradient]
                          maskTest: nil
                      displayDepth: displayDepth
               showPackageContents: showPackageContents];
}


- (instancetype) initWithColorMapper:(NSObject <FileItemMapping> *)colorMapperVal
                        colorPalette:(NSColorList *)colorPaletteVal
                       colorGradient:(float)colorGradientVal
                            maskTest:(FileItemTest *)maskTestVal
                        displayDepth:(int)displayDepth
                 showPackageContents:(BOOL)showPackageContents {
  if (self = [super initWithDisplayDepth: displayDepth showPackageContents: showPackageContents]) {
    colorMapper = [colorMapperVal retain];
    colorPalette = [colorPaletteVal retain];
    colorGradient = colorGradientVal;
    maskTest = [maskTestVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [colorMapper release];
  [colorPalette release];
  [maskTest release];
  
  [super dealloc];
}


- (instancetype) settingsWithChangedColorMapper:(NSObject <FileItemMapping> *)colorMapperVal {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapperVal
                                             colorPalette: colorPalette
                                            colorGradient: colorGradient
                                                 maskTest: maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedColorPalette:(NSColorList *)colorPaletteVal {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapper
                                             colorPalette: colorPaletteVal
                                            colorGradient: colorGradient
                                                 maskTest: maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedColorGradient:(float) colorGradientVal {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapper
                                             colorPalette: colorPalette
                                            colorGradient: colorGradientVal
                                                 maskTest: maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedMaskTest:(FileItemTest *)maskTestVal {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapper
                                             colorPalette: colorPalette
                                            colorGradient: colorGradient
                                                 maskTest: maskTestVal
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedDisplayDepth:(int) displayDepth {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapper
                                             colorPalette: colorPalette
                                            colorGradient: colorGradient
                                                 maskTest: maskTest
                                             displayDepth: displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedShowPackageContents:(BOOL) showPackageContents {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapper
                                             colorPalette: colorPalette
                                            colorGradient: colorGradient
                                                 maskTest: maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}


- (NSObject <FileItemMapping> *)colorMapper {
  return colorMapper;
}

- (NSColorList *)colorPalette {
  return colorPalette;
}

- (float) colorGradient {
  return colorGradient;
}

- (FileItemTest *)maskTest {
  return maskTest;
}

@end // @implementation TreeDrawerSettings


NSColorList  *defaultColorPalette = nil;

@implementation TreeDrawerSettings (PrivateMethods)

+ (NSColorList *)defaultColorPalette {
  if (defaultColorPalette == nil) {
    NSColorList  *colorList = [[NSColorList alloc] initWithName: @"DefaultTreeDrawerPalette"];

    [colorList insertColor: NSColor.blueColor    key: @"blue"    atIndex: 0];
    [colorList insertColor: NSColor.redColor     key: @"red"     atIndex: 1];
    [colorList insertColor: NSColor.greenColor   key: @"green"   atIndex: 2];
    [colorList insertColor: NSColor.cyanColor    key: @"cyan"    atIndex: 3];
    [colorList insertColor: NSColor.magentaColor key: @"magenta" atIndex: 4];
    [colorList insertColor: NSColor.orangeColor  key: @"orange"  atIndex: 5];
    [colorList insertColor: NSColor.yellowColor  key: @"yellow"  atIndex: 6];
    [colorList insertColor: NSColor.purpleColor  key: @"purple"  atIndex: 7];

    defaultColorPalette = colorList;
  }

  return defaultColorPalette;
}

@end // @implementation TreeDrawerSettings (PrivateMethods)
