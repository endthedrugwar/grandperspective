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


- (instancetype) initWithColorMapper:(NSObject <FileItemMapping> *)colorMapper
                        colorPalette:(NSColorList *)colorPalette
                       colorGradient:(float)colorGradient
                            maskTest:(FileItemTest *)maskTest
                        displayDepth:(int)displayDepth
                 showPackageContents:(BOOL)showPackageContents {
  if (self = [super initWithDisplayDepth: displayDepth showPackageContents: showPackageContents]) {
    _colorMapper = [colorMapper retain];
    _colorPalette = [colorPalette retain];
    _colorGradient = colorGradient;
    _maskTest = [maskTest retain];
  }
  
  return self;
}

- (void) dealloc {
  [_colorMapper release];
  [_colorPalette release];
  [_maskTest release];
  
  [super dealloc];
}


- (instancetype) settingsWithChangedColorMapper:(NSObject <FileItemMapping> *)colorMapper {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedColorPalette:(NSColorList *)colorPalette {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: colorPalette
                                            colorGradient: self.colorGradient
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedColorGradient:(float) colorGradient {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: colorGradient
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedMaskTest:(FileItemTest *)maskTest {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                 maskTest: maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedDisplayDepth:(int) displayDepth {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                 maskTest: self.maskTest
                                             displayDepth: displayDepth
                                      showPackageContents: self.showPackageContents] autorelease];
}

- (instancetype) settingsWithChangedShowPackageContents:(BOOL) showPackageContents {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth
                                      showPackageContents: showPackageContents] autorelease];
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
