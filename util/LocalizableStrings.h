#import <Cocoa/Cocoa.h>

__attribute__((annotate("returns_localized_nsstring")))
static inline NSString *LocalizationNotNeeded(NSString *s) {
  return s;
}

@interface LocalizableStrings : NSObject {
}

+ (NSString *)localizedAndEnumerationString:(NSArray *)items;

+ (NSString *)localizedOrEnumerationString:(NSArray *)items;
                 
+ (NSString *)localizedEnumerationString:(NSArray *)items
                            pairTemplate:(NSString *)pairTemplate
                       bootstrapTemplate:(NSString *)bootstrapTemplate
                       repeatingTemplate:(NSString *)repeatingTemplate;

@end
