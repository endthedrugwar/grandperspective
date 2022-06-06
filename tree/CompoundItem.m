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

+ (void)visitLeavesMaybeNil:(Item *)item callback:(void(^)(FileItem *))callback {
  if (item != nil) {
    [CompoundItem visitLeaves: item callback: callback];
  }
}

+ (void)visitLeaves:(Item *)item callback:(void(^)(FileItem *))callback {
  if (item.isVirtual) {
    [CompoundItem visitLeaves: ((CompoundItem *)item).first callback: callback];
    [CompoundItem visitLeaves: ((CompoundItem *)item).second callback: callback];
  } else {
    callback((FileItem *)item);
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
  NSAssert([newItem itemSize] == [_first itemSize], @"Sizes must be equal.");
  
  if (_first != newItem) {
    [_first release];
    _first = [newItem retain];
  }
}

// Custom "setter", which enforces that size remains the same
- (void) replaceSecond:(Item *)newItem {
  NSAssert([newItem itemSize] == [_second itemSize], @"Sizes must be equal.");
  
  if (_second != newItem) {
    [_second release];
    _second = [newItem retain];
  }
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
