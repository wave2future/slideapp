//
//  MvrStorage.h
//  Mover3-iPad
//
//  Created by ∞ on 08/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrItem.h"

@interface MvrStorage : NSObject {
	NSString* itemsDirectory, * metadataDirectory;
	
	NSMutableSet* storedItemsSet;
	NSMutableSet* knownFiles;
}

- (id) initWithItemsDirectory:(NSString*) i metadataDirectory:(NSString*) m;

@property(readonly) NSString* itemsDirectory, * metadataDirectory;

// @property(readonly) NSSet* storedItems;
- (NSSet*) storedItems;
- (void) addStoredItemsObject:(MvrItem*) i;
- (void) removeStoredItemsObject:(MvrItem*) i;

@property(readonly) NSMutableSet* mutableStoredItems;

- (void) adoptPersistentItem:(MvrItem*) i;

- (void) migrateFrom30StorageCentralMetadata:(id) meta;

- (BOOL) hasItemForFileAtPath:(NSString*) path;
- (BOOL) isPathInItemsDirectory:(NSString*) path;


+ (BOOL) hasUserVisibleFileRepresentation:(MvrItem*) i;

+ (NSString*) userVisibleFilenameForItem:(MvrItem*) i attempt:(NSUInteger) attempt;
+ (NSString *) userVisibleFilenameForItem:(MvrItem *)i unacceptableFilenames:(NSSet*) filenames;

@end
