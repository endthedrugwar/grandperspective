#import <Cocoa/Cocoa.h>


// Note: Instances are immutable (and as a result, the class is thread-safe). 
@interface UniformType : NSObject {
  NSString  *uti;
  NSString  *description;

  // An immutable set of "UniformType"s
  NSSet  *parents;
}

// Overrides super's designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithUniformTypeIdentifier:(NSString *)uti
                                   description:(NSString *)description
                                       parents:(NSArray *)parentTypes NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSString *uniformTypeIdentifier;

@property (nonatomic, readonly, copy) NSString *description;

@property (nonatomic, readonly, copy) NSSet *parentTypes;

/* Dynamically constructs the set of types that the receiving type conforms to (directly or
 * indirectly).
 *
 * Conformance of a given type, typeA, to another type, typeB can be tested as follows:
 *
 *   (typeA == typeB) || ([typeA.ancestorTypes containsObject: typeB])
 *
 * The reason that there is no method implementing this test directly is that for multiple
 * subsequent conformance tests for the same type, which is typical usage, you should construct the
 * ancestor set only once. This could easily be forgotten if there would be a -conformsTo:
 * convenience method. Furthermore, such a method would also hide the execution overhead associated
 * with conformance tests.
 */
@property (nonatomic, readonly, copy) NSSet *ancestorTypes;

@end
