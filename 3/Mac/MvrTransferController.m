//
//  MvrTransferController.m
//  Mover Connect
//
//  Created by ∞ on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrTransferController.h"

#import "Network+Storage/MvrChannel.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrPacketParser.h"

#import "Network+Storage/MvrGenericItem.h"
#import "Network+Storage/MvrItemStorage.h"

#import "MvrTextItem.h"


static NSArray* MvrTypeForExtension(NSString* ext) {
	if ([ext isEqual:@"m4v"])
		return [NSArray arrayWithObject:(id) kUTTypeMPEG4];
	
	return NSMakeCollectable(UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, (CFStringRef) ext, NULL));
}


@implementation MvrTransferController

- (id) init;
{
	if (self = [super init]) {
		[MvrPacketParser setAutomaticConsumptionThreshold:1024 * 1024];
		
		channels = [NSMutableSet new];
		channelsByIncoming = [L0Map new];

		wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiConduitPort options:kMvrUseConduitService|kMvrAllowBrowsingForConduitService|kMvrAllowConnectionsFromConduitService];
		wifiObserver = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	}
	
	return self;
}

- (BOOL) enabled;
{
	return wifi.enabled;
}
- (void) setEnabled:(BOOL) e;
{
	wifi.enabled = e;
}

@synthesize channels;


#pragma mark Outgoing

- (void) sendItemFile:(NSString*) file throughChannel:(id <MvrChannel>) c;
{
	NSString* title = [[NSFileManager defaultManager] displayNameAtPath:file];
	
	NSString* ext = [file pathExtension];
	NSArray* types = MvrTypeForExtension(ext);
	
	NSString* filename = [file lastPathComponent];
	NSDictionary* md = [NSDictionary dictionaryWithObjectsAndKeys:
						title, kMvrItemTitleMetadataKey,
						filename, kMvrItemOriginalFilenameMetadataKey,
						nil];
	
	MvrItemStorage* is = [MvrItemStorage itemStorageFromFileAtPath:file options:kMvrItemStorageDoNotTakeOwnershipOfFile error:NULL];
	if (is && [types count] > 0) {
		MvrGenericItem* item = [[MvrGenericItem alloc] initWithStorage:is type:[types objectAtIndex:0] metadata:md];
		[c beginSendingItem:item];
	}
}

- (NSArray*) knownPasteboardTypes;
{
	return [NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, NSTIFFPboardType, (id) kUTTypePNG, nil];
}

- (BOOL) canSendContentsOfPasteboard:(NSPasteboard*) pb;
{
	L0Log(@"%@", [pb types]);
	
	BOOL containsKnownType = NO;
	
	NSArray* types = [pb types];
	if ([types containsObject:NSStringPboardType] || [types containsObject:NSTIFFPboardType] || [types containsObject:(id) kUTTypePNG])
		containsKnownType = YES;
	
	NSArray* files = L0As(NSArray, [pb propertyListForType:NSFilenamesPboardType]);
	for (NSString* file in files) {
		containsKnownType = YES;
		
		BOOL isDir;
		if (![[NSFileManager defaultManager] fileExistsAtPath:[files objectAtIndex:0] isDirectory:&isDir] || isDir)
			return NO;
	}
	
	return containsKnownType;
}

- (void) sendContentsOfPasteboard:(NSPasteboard*) pb throughChannel:(id <MvrChannel>) c;
{
	BOOL sent = NO;
	
	for (NSString* path in L0As(NSArray, [pb propertyListForType:NSFilenamesPboardType])) {
		sent = YES;
		[self sendItemFile:path throughChannel:c];
	}
	
	if (sent)
		return;
	
	NSImage* image = [[NSImage alloc] initWithPasteboard:pb];
	if (image && [[image representations] count] > 0 && [[[image representations] objectAtIndex:0] isKindOfClass:[NSBitmapImageRep class]]) {
		
		NSBitmapImageRep* rep = [[image representations] objectAtIndex:0];
		NSData* d = [rep representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];
		
		MvrItemStorage* s = [MvrItemStorage itemStorageWithData:d];
		MvrGenericItem* item = [[MvrGenericItem alloc] initWithStorage:s type:(id) kUTTypePNG metadata:nil];
		
		[c beginSendingItem:item];
		return;
	}
	
	// TODO URL autodetection.
	
	NSString* str = [pb stringForType:NSStringPboardType];
	if (str) {
		MvrTextItem* text = [[MvrTextItem alloc] initWithText:str];
		[c beginSendingItem:text];
	}
}

#pragma mark Incoming

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[channelsByIncoming setObject:c forKey:incoming];
}

- (void) incomingTransfer:(id <MvrIncoming>) incoming didEndReceivingItem:(MvrItem*) i;
{
	if (!i)
		return;
	
	MvrModernWiFiChannel* chan = [channelsByIncoming objectForKey:incoming];
	
	if (!chan.allowsConduitConnections)
		return;
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	NSAssert([dirs count] != 0, @"We know where the downloads directory(/ies) is (are)");
	NSString* downloadDir = [dirs objectAtIndex:0];
	downloadDir = [downloadDir stringByAppendingPathComponent:@"Mover Items"];
	BOOL isDir;
	
	NSString* baseName = [i.metadata objectForKey:kMvrItemOriginalFilenameMetadataKey], * ext = nil;
	
	if (!baseName) {
		baseName = [NSString stringWithFormat:NSLocalizedString(@"From %@", @"Base for received filenames"), chan.displayName];
		ext = NSMakeCollectable(UTTypeCopyPreferredTagWithClass((CFStringRef) i.type, kUTTagClassFilenameExtension));
		
		if (!ext && [i.type isEqual:(id) kUTTypeUTF8PlainText])
			ext = @"txt";
	} else {
		ext = [baseName pathExtension];
		baseName = [baseName stringByDeletingPathExtension];
	}
	
	// !!! Check whether the sanitization of the path parts is sane or not.
	baseName = [baseName stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	ext = [ext stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	
	BOOL goOn = ([fm fileExistsAtPath:downloadDir isDirectory:&isDir] && isDir) || [fm createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
	
	if (goOn && ext) {
		NSString* attempt = baseName;
		
		int idx = 1;
		BOOL alreadyExists;
		NSString* targetPath;
		do {
			targetPath = [downloadDir stringByAppendingPathComponent:[attempt stringByAppendingPathExtension:ext]];
			alreadyExists = [fm fileExistsAtPath:targetPath];
			
			if (alreadyExists) {
				idx++;
				attempt = [baseName stringByAppendingFormat:@" (%d)", idx];
			}
		} while (alreadyExists);
		
		BOOL ok = [fm copyItemAtPath:i.storage.path toPath:targetPath error:NULL];
		
		if (ok) {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DownloadFileFinished" object:targetPath];
			[[NSWorkspace sharedWorkspace] selectFile:targetPath inFileViewerRootedAtPath:@""];
		}
	}
	
	[channelsByIncoming removeObjectForKey:incoming];
	[i invalidate];
}

#pragma mark Channels

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	MvrModernWiFiChannel* c = (MvrModernWiFiChannel*) channel;
	
	if (c.allowsConduitConnections)
		[[self mutableSetValueForKey:@"channels"] addObject:c];
}

- (void) scanner:(id <MvrScanner>)s didRemoveChannel:(id <MvrChannel>)channel;
{
	[[self mutableSetValueForKey:@"channels"] removeObject:channel];
}

#pragma mark Mover Platform info stuff.

- (NSString *) displayNameForSelf;
{
	NSString* name;
	NSHost* me = [NSHost currentHost];
	
	// 10.6-only
	if ([me respondsToSelector:@selector(localizedName)])
		name = [me localizedName];
	else
		name = [me name];
	
	return name;
}

- (L0UUID*) identifierForSelf;
{
	if (!identifier)
		identifier = [L0UUID UUID];
	
	return identifier;
}

- (MvrAppVariant) variant;
{
	return kMvrAppVariantNotMover;
}

- (NSString *) variantDisplayName;
{
	return @"Mover Waypoint";
}

- (id) platform;
{
	return kMvrAppleMacOSXPlatform;
}

- (double) version;
{
	return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] doubleValue];
}

- (NSString *) userVisibleVersion;
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];	
}

@end
