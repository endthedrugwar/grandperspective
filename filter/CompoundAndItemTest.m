#import "CompoundAndItemTest.h"


@implementation CompoundAndItemTest

- (BOOL) testFileItem:(FileItem*)item {
  int  max = [subTests count];
  int  i = 0;
  while (i < max) {
    if (! [[subTests objectAtIndex:i++] testFileItem:item]) {
      // Short-circuit evaluation.
      return NO;
    }
  }

  return YES;
}


- (NSString*) bootstrapDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) and (%@)" , @"tests", 
           @"AND-test with 1: sub test, and 2: another sub test" );
}

- (NSString*) repeatingDescriptionTemplate {
  return NSLocalizedStringFromTable( 
           @"(%@) and %@" , @"tests", 
           @"AND-test with 1: sub test, and 2: two or more other sub tests" );
}

@end
