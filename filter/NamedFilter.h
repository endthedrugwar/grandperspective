#import <Cocoa/Cocoa.h>


@class Filter;

@interface NamedFilter : NSObject {
}

+ (NamedFilter *)emptyFilterWithName:(NSString *)name;
+ (NamedFilter *)namedFilter:(Filter *)filter name:(NSString *)name;

// Overrides designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithFilter:(Filter *)filter
                           name:(NSString *)name;

- (instancetype) initWithFilter:(Filter *)filter
                           name:(NSString *)name
                       implicit:(BOOL)implicit NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) Filter *filter;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *localizedName;
@property (nonatomic, readonly) BOOL isImplicit;

@end
