#import "CompoundItem.h"

#import "FileItem.h"

@implementation CompoundItem

+ (Item *)compoundItemWithFirst:(Item *)first second:(Item *)second {
  if (first != nil && second != nil) {
    return [[[CompoundItem allocWithZone: [first zone]] initWithFirst: first
                                                               second: second] autorelease];
  }
  if (first != nil) {
    return first;
  }
  if (second != nil) {
    return second;
  }
  return nil;
}

+ (FileItem *)findFileItemChild:(Item *)item predicate:(BOOL(^)(FileItem *))predicate {
  FileItem  *retVal;

  if (item.isVirtual) {
    retVal = [CompoundItem findFileItemChild: ((CompoundItem *)item).second predicate: predicate];
    if (retVal == nil) {
      retVal = [CompoundItem findFileItemChild: ((CompoundItem *)item).first predicate: predicate];
    }

  } else {
    retVal = predicate((FileItem *)item) ? (FileItem *)item : nil;
  }

  return retVal;
}

+ (FileItem *)findFileItemChildMaybeNil:(nullable Item *)item
                              predicate:(BOOL(^)(FileItem *))predicate {
  return (item != nil) ? [CompoundItem findFileItemChild: item predicate: predicate] : nil;
}

+ (void)visitFileItemChildren:(Item *)item callback:(void(^)(FileItem *))callback {
  if (item.isVirtual) {
    [CompoundItem visitFileItemChildren: ((CompoundItem *)item).first callback: callback];
    [CompoundItem visitFileItemChildren: ((CompoundItem *)item).second callback: callback];
  } else {
    callback((FileItem *)item);
  }
}

+ (void)visitFileItemChildrenMaybeNil:(Item *)item callback:(void(^)(FileItem *))callback {
  if (item != nil) {
    [CompoundItem visitFileItemChildren: item callback: callback];
  }
}

- (instancetype) initWithFirst:(Item *)first second:(Item *)second {
  NSAssert(first != nil && second != nil, @"Both values must be non nil.");
  
  if (self = [super initWithItemSize:(first.itemSize + second.itemSize)]) {
    _first = [first retain];
    _second = [second retain];
    numFiles = first.numFiles + second.numFiles;
  }

  return self;
}


- (void) dealloc {
  [_first release];
  [_second release];
  
  [super dealloc];
}


- (NSString *)description {
  return [NSString stringWithFormat:@"CompoundItem(%@, %@)", self.first, self.second];
}


- (FILE_COUNT) numFiles {
  return numFiles;
}

- (BOOL) isVirtual {
  return YES;
}


// Custom "setter", which enforces that size remains the same
- (void) replaceFirst:(Item *)newItem {
  NSAssert(newItem.itemSize == _first.itemSize, @"Sizes must be equal.");
  
  if (_first != newItem) {
    [_first release];
    _first = [newItem retain];
  }
}

// Custom "setter", which enforces that size remains the same
- (void) replaceSecond:(Item *)newItem {
  NSAssert(newItem.itemSize == _second.itemSize, @"Sizes must be equal.");
  
  if (_second != newItem) {
    [_second release];
    _second = [newItem retain];
  }
}

// Overrides abstract method in Item
- (void) visitFileItemDescendants:(void(^)(FileItem *))callback {
  [_first visitFileItemDescendants: callback];
  [_second visitFileItemDescendants: callback];
}

// Overrides abstract method in Item
- (FileItem *)findFileItemDescendant:(BOOL(^)(FileItem *))predicate {
  FileItem *retVal = [_first findFileItemDescendant: predicate];
  if (retVal == nil) {
    retVal = [_second findFileItemDescendant: predicate];
  }

  return retVal;
}

- (FileItem *)findFileItemWithLabel:(NSString *)label {
  if (_first.isVirtual) {
    FileItem *found = [((CompoundItem *)_first)findFileItemWithLabel: label];
    if (found != nil) {
      return found;
    }
  }
  else if ([((FileItem *)_first).label isEqualToString: label]) {
    return (FileItem *)_first;
  }

  if (_second.isVirtual) {
    FileItem *found = [((CompoundItem *)_second)findFileItemWithLabel: label];
    if (found != nil) {
      return found;
    }
  }
  else if ([((FileItem *)_second).label isEqualToString: label]) {
    return (FileItem *)_second;
  }

  return nil;
}

@end
