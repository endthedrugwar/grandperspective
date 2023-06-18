#import "Item.h"

#import "PreferencesPanelControl.h"

@implementation Item

// Overrides super's designated initialiser.
- (instancetype) init {
  return [self initWithItemSize:0];
}

- (instancetype) initWithItemSize:(ITEM_SIZE)itemSize {
  if (self = [super init]) {
    _itemSize = itemSize;
  }
  
  return self;
}

- (void) visitFileItemDescendants:(void(^)(FileItem *))callback {
  NSAssert(NO, @"Abstract method");
}

- (FileItem *)findFileItemDescendant:(BOOL(^)(FileItem *))predicate {
  NSAssert(NO, @"Abstract method");
  return nil;
}

- (FILE_COUNT) numFiles {
  return 0;
}

- (void) setItemSize:(ITEM_SIZE)itemSize {
  // Disabled check below as CompoundItem replaceFirst:second now violates it (by design)
  // NSAssert(_itemSize == 0, @"Cannot change itemSize after it has been set");

  _itemSize = itemSize;
}

- (BOOL) isVirtual {
  return NO;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Item(size=%qu)", self.itemSize];
}

@end
