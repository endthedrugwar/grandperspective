#import "DirectoryItem.h"

#import "PlainFileItem.h"
#import "UniformTypeInventory.h"


@implementation DirectoryItem

// Overrides designated initialiser
- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(ITEM_SIZE)size
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  NSAssert(NO, @"Initialize without size.");
  return [self initWithLabel: nil parent: nil flags: 0 creationTime: 0 modificationTime: 0
                  accessTime: 0];
}


- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  
  if (self = [super initWithLabel: label
                           parent: parent
                             size: 0
                            flags: flags
                     creationTime: creationTime
                 modificationTime: modificationTime
                       accessTime: accessTime]) {
    _fileItems = nil;
    _directoryItems = nil;

    _rescanFlags = DirectoryIsUpToDate;
  }
  return self;
}


- (void) dealloc {
  [_fileItems release];
  [_directoryItems release];

  [super dealloc];
}

// Overrides abstract method in FileItem
- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  return [[[DirectoryItem allocWithZone: [newParent zone]] 
              initWithLabel: self.label
                     parent: newParent
                      flags: self.fileItemFlags
               creationTime: self.creationTime
           modificationTime: self.modificationTime
                 accessTime: self.accessTime
            ] autorelease];
}

// Overrides abstract method in Item
- (void) visitFileItemDescendants:(void(^)(FileItem *))callback {
  callback(self);
  [_fileItems visitFileItemDescendants: callback];
  [_directoryItems visitFileItemDescendants: callback];
}

// Overrides abstract method in Item
- (FileItem *)findFileItemDescendant:(BOOL(^)(FileItem *))predicate {
  if (predicate(self)) {
    return self;
  }

  FileItem *retVal;

  retVal = [_fileItems findFileItemDescendant: predicate];
  if (retVal == nil) {
    retVal = [_directoryItems findFileItemDescendant: predicate];
  }

  return retVal;
}

// Special "setter" with additional constraints
- (void) setFileItems:(Item *)fileItems
       directoryItems:(Item *)dirItems {
  NSAssert(_fileItems == nil && _directoryItems == nil, @"Contents should only be set once.");
  
  _fileItems = [fileItems retain];
  _directoryItems = [dirItems retain];

  self.itemSize = fileItems.itemSize + dirItems.itemSize;
}

- (void) replaceFileItems:(Item *)newItem {
  NSAssert(newItem.itemSize == self.fileItems.itemSize, @"Sizes must be equal.");

  if (_fileItems != newItem) {
    [_fileItems release];
    _fileItems = [newItem retain];
  }
}

- (void) replaceDirectoryItems:(Item *)newItem {
  NSAssert(newItem.itemSize == self.directoryItems.itemSize, @"Sizes must be equal.");

  if (_directoryItems != newItem) {
    [_directoryItems release];
    _directoryItems = [newItem retain];
  }
}

- (Item *)childItems {
  return [CompoundItem compoundItemWithFirst: _fileItems second: _directoryItems];
}

- (FileItem *)itemWhenHidingPackageContents {
  if ([self isPackage]) {
    UniformType  *fileType = [[UniformTypeInventory defaultUniformTypeInventory]
                              uniformTypeForExtension: [self systemPathComponent].pathExtension];
  
    // Note: This item is short-lived, so it is allocated in the default zone.
    return [[[PlainFileItem alloc]
             initWithLabel: self.label
                    parent: self.parentDirectory
                      size: self.itemSize
                      type: fileType
                     flags: self.fileItemFlags
              creationTime: self.creationTime
          modificationTime: self.modificationTime
                accessTime: self.accessTime
              ] autorelease];
  }
  else {
    return self;
  }
}


- (NSString *)description {
  return [NSString stringWithFormat:
          @"DirectoryItem(%@, %qu)", self.label, self.itemSize];
}


- (FILE_COUNT) numFiles {
  return self.fileItems.numFiles + self.directoryItems.numFiles;
}

- (BOOL) isDirectory {
  return YES;
}

@end // @implementation DirectoryItem
