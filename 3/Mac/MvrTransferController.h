//
//  MvrTransferController.h
//  Mover Connect
//
//  Created by ∞ on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Network+Storage/MvrModernWiFi.h"
#import "Network+Storage/MvrModernWiFiChannel.h"
#import "Network+Storage/MvrScannerObserver.h"

#import "Network+Storage/MvrPlatformInfo.h"

#import <MuiKit/MuiKit.h>


@interface MvrTransferController : NSObject <MvrScannerObserverDelegate, MvrPlatformInfo> {
	MvrModernWiFi* wifi;
	MvrScannerObserver* wifiObserver;
	
	L0Map* channelsByIncoming;
	
	NSMutableSet* channels;
	
	L0UUID* identifier;
}

+ transferController;

@property BOOL enabled;

@property(readonly) NSMutableSet* channels;

- (void) sendItemFile:(NSString*) file throughChannel:(id <MvrChannel>) c;

@end
