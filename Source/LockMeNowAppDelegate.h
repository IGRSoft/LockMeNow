//
//  LockMeNowAppDelegate.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import "IGRUserDefaults.h"

@class StartAtLoginController;
@class KeyListener;

@interface LockMeNowAppDelegate : NSObject <NSApplicationDelegate>
{
	StartAtLoginController *loginController;
}

@property (nonatomic) IBOutlet NSWindow		*window;
@property (nonatomic) IBOutlet NSMenu		*statusMenu;
@property (nonatomic) IBOutlet NSTabView	*tabView;
@property (nonatomic) IBOutlet KeyListener  *keyListener;

@property (nonatomic) IBOutlet NSImageView	*bluetoothStatus;

@property (nonatomic) IBOutlet NSView       *lockBlockView;
@property (nonatomic) IBOutlet NSButton     *donateButton;

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
