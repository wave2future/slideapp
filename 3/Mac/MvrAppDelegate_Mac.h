//
//  MoverWaypointAppDelegate.h
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Network+Storage/MvrPlatformInfo.h"

#import "MvrDevicesLineView.h"
#import "MvrTransferController.h"

#import "MvrPreferencesController.h"

#import <MuiKit/MuiKit.h>

@interface MvrAppDelegate_Mac : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    IBOutlet NSWindow * window;
	CGFloat originalWindowHeight;
	
	IBOutlet NSArrayController* channelsController;
	IBOutlet NSArrayController* pickerChannelsController;
	
	IBOutlet MvrDevicesLineView* devicesView;
	
	MvrTransferController* transfer;
	
	IBOutlet NSPanel* channelPicker;

	id channelPickerDelegate;
	SEL channelPickerSelector;
	id channelPickerContext;
	
	IBOutlet NSWindow* preferencesPanel;
	IBOutlet MvrPreferencesController* preferences;
	
	IBOutlet NSWindow* aboutPanel;
	IBOutlet NSTextField* aboutVersionLabel;
	IBOutlet NSTextView* legalitiesTextView;
	
	IBOutlet NSMenu* applicationMenu;
}

- (IBAction) openMoverPlusAppStore:(id) sender;
- (IBAction) openMoverLiteAppStore:(id) sender;

@property(readonly) MvrTransferController* transfer;

// - (void) didPickChannel:(id <MvrChannel>) picked context:(id) ctx;
- (void) beginPickingChannelWithDelegate:(id) delegate selector:(SEL) selector context:(id) ctx;

- (IBAction) cancelPicking:(id) sender;
- (IBAction) performPicking:(id) sender;

@property(readonly) MvrPreferencesController* preferences;

- (IBAction) open:(id) sender;

- (IBAction) revealDownloadsInFinder:(id) sender;

- (void) warnAboutMissingContacts;

- (IBAction) showAboutWindow:(id) sender;

- (void) showFirstTimeDeviceFoundAlertIfNeeded;

- (IBAction) showMainWindow:(id) sender;

@end

static inline MvrAppDelegate_Mac* MvrApp() {
	return (MvrAppDelegate_Mac*) [NSApp delegate];
}
