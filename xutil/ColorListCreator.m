#import "ColorListCreator.h"


@interface ColorListCreator (PrivateMethods) 

+ (void) createCoffeeBeans;
+ (void) createPastelPapageno;
+ (void) createBlueSkyTulips;
+ (void) createMonaco;
+ (void) createWarmFall;
+ (void) createMossAndLichen;
+ (void) createMatbord;
+ (void) createBujumbura;
+ (void) createAutumn;
+ (void) createOliveSunset;
+ (void) createRainbow;
+ (void) createOrigamiMice;
+ (void) createSeussSiteWebsite;
+ (void) createFengShui;
+ (void) createDaytona;
+ (void) createFlyingGeese;
+ (void) createLagoonNebula;
+ (void) createAutumnBlush;
+ (void) createColorFile: (NSString*)name hexColors: (NSArray*) colors;

@end

static NSString*  hexChars = @"0123456789ABCDEF";

float valueOfHexPair(NSString* hexString) {
  int  val = 0;
  int  i;
  for (i = 0; i < [hexString length]; i++) { 
    val = val * 16;
    NSRange  r = [hexChars rangeOfString: 
                    [hexString substringWithRange: NSMakeRange(i, 1)]
                           options: NSCaseInsensitiveSearch];
    val += r.location;
  }
  
  return (val / 255.0);
}


NSColor* colorForHexString(NSString* hexColor) {
  float  r = valueOfHexPair([hexColor substringWithRange: NSMakeRange(0, 2)]);
  float  g = valueOfHexPair([hexColor substringWithRange: NSMakeRange(2, 2)]);
  float  b = valueOfHexPair([hexColor substringWithRange: NSMakeRange(4, 2)]);

  NSLog(@"%f, %f, %f", r, g, b);

  return [NSColor colorWithDeviceRed:r green:g blue:b alpha:0];
}


@implementation ColorListCreator

+ (void) createColorListFiles {
  [self createCoffeeBeans];
  [self createPastelPapageno];
  [self createBlueSkyTulips];
  [self createMonaco];
  [self createWarmFall];
  [self createMossAndLichen];
  [self createMatbord];
  [self createBujumbura];
  [self createAutumn];
  [self createOliveSunset];
  [self createRainbow];
  [self createOrigamiMice];
  [self createSeussSiteWebsite];
  [self createFengShui];
  [self createDaytona];
  [self createFlyingGeese];
  [self createLagoonNebula];
  [self createAutumnBlush];
}

@end

@implementation ColorListCreator (PrivateMethods)

+ (void) createCoffeeBeans {
  NSArray  *colors = @[@"CC3333", @"CC9933", @"FFCC66", @"CC6633", @"CC6666", @"993300", @"666600"];

  [self createColorFile: @"CoffeeBeans" hexColors: colors];
}

+ (void) createPastelPapageno {
  NSArray  *colors = @[@"66FF99", @"FFEB66", @"FFAC66", @"FF66AB", @"66C4FF"];

  [self createColorFile: @"PastelPapageno" hexColors: colors];
}

+ (void) createBlueSkyTulips {
  NSArray  *colors = @[@"99CC66", @"336600", @"333399", @"CC6666", @"FF99CC", @"FF3333", @"FFCC66"];

  [self createColorFile: @"BlueSkyTulips" hexColors: colors];
}

+ (void) createMonaco {
  NSArray  *colors = @[@"7378D4", @"2A91D2", @"3DBFCC", @"38B236", @"D92130", @"DB4621", @"EC8921"];

  [self createColorFile: @"Monaco" hexColors: colors];
}

+ (void) createWarmFall { 
  NSArray  *colors = @[@"CCCC00", @"999900", @"666600", @"333300", @"CC6600", @"996600", @"663300",
                       @"FF6600", @"FF9900", @"FFCC00"];

  [self createColorFile: @"WarmFall" hexColors: colors];
}

+ (void) createMossAndLichen {
  NSArray  *colors = @[@"666633", @"999966", @"CCCC99", @"FFFFCC", @"99CCCC", @"009999", @"006666",
                       @"003333"];

  [self createColorFile: @"MossAndLichen" hexColors: colors];
}

+ (void) createMatbord {
  NSArray  *colors = @[@"ABA64B", @"FFD06B", @"D17F58", @"B7081A", @"292C31"];

  [self createColorFile: @"DiningTable" hexColors: colors];
}

+ (void) createBujumbura {
  NSArray  *colors = @[@"BE420E", @"BE6D0E", @"6B4F2E", @"CCA066", @"E0D752", @"A5BE0E", @"4197E3"];
               
  [self createColorFile: @"Bujumbura" hexColors: colors];
}

+ (void) createAutumn {
  NSArray  *colors = @[@"666633", @"336666", @"993333", @"FFCC00", @"FF9900"];
               
  [self createColorFile: @"Autumn" hexColors: colors];
}

+ (void) createOliveSunset {
  NSArray  *colors = @[@"99CCCC", @"3399CC", @"006699", @"003366", @"666600", @"999900", @"CCCC33",
                       @"CCCC99", @"FFFFCC", @"FF9966", @"CC0033", @"990033"];

  [self createColorFile: @"OliveSunset" hexColors: colors];
}

+ (void) createRainbow {
  NSArray  *colors = @[@"FFFF54", @"C8E64C", @"8CD466", @"4DC742", @"45D2B0", @"46ACD3", @"438CCB",
                       @"4262C7", @"5240C3", @"8C3FC0", @"D145C1", @"E64C8D", @"FF5454", @"FF8054",
                       @"FFA054", @"FFB554"];

  [self createColorFile: @"Rainbow" hexColors: colors];
}

+ (void) createOrigamiMice {
  NSArray  *colors = @[@"CE61A5", @"5AC3BD", @"C61400", @"8C8A6B", @"006152", @"5ABA10", @"8479AD",
                       @"DEB64A", @"C6CB00"];

  [self createColorFile: @"OrigamiMice" hexColors: colors];
}

+ (void) createSeussSiteWebsite {
  NSArray  *colors = @[@"5ABFC6", @"CE95C8", @"D1C57E", @"E85AAA", @"FF2626", @"009ACD", @"FFFF00",
                       @"FBBF51", @"FFF07A", @"9EFC7D", @"AAE009", @"58A866"];

  [self createColorFile: @"GreenEggs" hexColors: colors];
}

+ (void) createFengShui {
  NSArray  *colors = @[@"DF4527", @"E87D18", @"D39907", @"F7C600", @"FEFA54", @"B7DD7E", @"7CC6A2",
                       @"8FCDEA", @"007CC6"];

  [self createColorFile: @"FengShui" hexColors: colors];
}

+ (void) createDaytona {
  NSArray  *colors = @[@"996600", @"CC9933", @"CCCC66", @"FFFF99", @"3399FF", @"99CCFF", @"003399",
                       @"99FF99", @"66FF33", @"339900"];

  [self createColorFile: @"Daytona" hexColors: colors];
}

+ (void) createFlyingGeese {
  NSArray  *colors = @[@"F948D7", @"DD43D9", @"8A53D1", @"586EA0", @"479FCF", @"6A7469", @"A29E57",
                       @"D9C447", @"FAD843"];

  [self createColorFile: @"FlyingGeese" hexColors: colors];
}

+ (void) createLagoonNebula {
  NSArray  *colors = @[@"CFAD4B", @"5A272C", @"98C8D6", @"F4AD6F", @"845D4E", @"D86562", @"9ED5AE",
                       @"325086"];

  [self createColorFile: @"LagoonNebula" hexColors: colors];
}

+ (void) createAutumnBlush {
  NSArray  *colors = @[@"B00F5D", @"CA6841", @"EFC53D", @"FAD779", @"64AF9A", @"C5DCD2", @"66443B",
                       @"BAA29E", @"EAE4D4"];

  [self createColorFile: @"AutumnBlush" hexColors: colors];
}

+ (void) createColorFile: (NSString*)name hexColors: (NSArray*) colors {
  NSColorList  *colorList = [[NSColorList alloc] initWithName: name];

  int  i = 0;
  while (i < colors.count) {
    NSString  *colorString = [colors objectAtIndex: i];
    
    [colorList insertColor: colorForHexString(colorString) key: colorString atIndex: i++];
  }

  [colorList writeToFile: nil];
}

@end // @implementation ColorListCreator (PrivateMethods)
