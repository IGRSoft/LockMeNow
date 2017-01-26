//
//  LMNLockMeNowApp.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

@class StartAtLoginController;
@class LMNKeyListener;

@interface LMNLockMeNowApp : NSObject <NSApplicationDelegate>
{
	StartAtLoginController *loginController;
}

@property (weak) IBOutlet NSWindow       *window;
@property (weak) IBOutlet NSMenu         *statusMenu;
@property (weak) IBOutlet NSTabView      *tabView;
@property (weak) IBOutlet LMNKeyListener *keyListener;

@property (weak) IBOutlet NSImageView	*bluetoothStatus;

@property (weak) IBOutlet NSView        *lockBlockView;

@property (weak) IBOutlet NSButton              *sendMailCheckbox;
@property (weak) IBOutlet NSProgressIndicator   *patchASLProgress;
@property (weak) IBOutlet NSTextField           *patchStatus;
@property (weak) IBOutlet NSComboBox            *thiefPhotoQuality;

@property (weak) IBOutlet NSTextField   *aboutText;

// Status Item
@property (strong, nonatomic) NSStatusItem *statusItem;

- (IBAction)doUnLock:(id)sender;
- (IBAction)doLock:(id)sender;

- (IBAction)goToURL:(id)sender;

- (IBAction)openPrefs:(id)sender;
- (IBAction)changeDevice:(id)sender;

- (IBAction)setMonitoringUSBDevice:(id)sender;
- (IBAction)setMonitoringBluetooth:(id)sender;

- (IBAction)setMenuIcon:(id)sender;

- (NSString *)takePhoto;

@end
