//
//  MvrWiFi.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrScanner.h"

#import "MvrPlatformInfo.h"
#import "MvrScannerObserver.h"

#import "MvrModernWiFi.h" // for the options

@class MvrModernWiFi, MvrLegacyWiFi, L0KVODispatcher;

@interface MvrWiFi : NSObject <MvrScanner, MvrScannerObserverDelegate> {
	MvrModernWiFi* modernWiFi;
	MvrLegacyWiFi* legacyWiFi;

	NSMutableDictionary* channelsByIdentifier;
	MvrScannerObserver* modernObserver, * legacyObserver;
	
	BOOL jammed, enabled;
}

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info modernPort:(int) port legacyPort:(int) legacyPort modernOptions:(MvrModernWiFiOptions) opts;

@property(retain) MvrModernWiFi* modernWiFi;
@property(retain) MvrLegacyWiFi* legacyWiFi;

@end
