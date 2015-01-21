//
//  LockMeNowAppDelegate.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import "IGRUserDefaults.h"
#import <xpc/xpc.h>

@class PTHotKey;
@class IKImageView;
@class IOBluetoothDevice;
@class SRRecorderControl;
@class StartAtLoginController;

extern NSString *kGlobalHotKey;

typedef enum _BluetoothStatus {
	InRange = 0,
	OutOfRange
} BluetoothStatus;

typedef struct {
    const char *name;
    uint16_t productID;
} APPLE_MOBILE_DEVICE;

@interface LockMeNowAppDelegate : NSObject <NSApplicationDelegate, NSTabViewDelegate> {
	//Interface
	NSApplicationPresentationOptions appPresentationOptions;
	
	NSOperationQueue	*m_Queue;
	NSOperationQueue	*m_GUIQueue;
	bool				m_bShouldTerminate;
	
	//Bluetooth
	BluetoothStatus		m_BluetoothDevicePriorStatus;
	NSTimer				*m_BluetoothTimer;
	
	//USB
	int					m_iUSBDeviceID;
	DeviceType			m_iCurrentUSBDeviceType;
	NSString			*m_sUSBDeviceName;

	//TEst
	NSTimer				*m_TestTimer;
	
	//alert
	NSInteger			alertReturnStatus;
	NSString			*m_PriceDeviceLock;
	
	StartAtLoginController *loginController;
}

@property (nonatomic, strong) IBOutlet NSWindow				*window;
@property (nonatomic, strong) IBOutlet SRRecorderControl	*hotKeyControl;
@property (nonatomic, strong) IBOutlet NSMenu				*statusMenu;
@property (nonatomic, strong) IBOutlet NSTabView			*tabView;

@property (nonatomic, strong) PTHotKey						*hotKey;
@property (nonatomic, strong) IBOutlet IKImageView			*bluetoothStatus;
@property (nonatomic, strong) IBOutlet NSTextField			*bluetoothName;
@property (nonatomic) NSInteger								p_BluetoothTimerInterval;
@property (nonatomic, strong) IBOutlet NSProgressIndicator	*spinner;
@property (nonatomic) BOOL	bMonitoring;
@property (nonatomic) BOOL	bEncription;
@property (nonatomic) BOOL	isJustLock;

@property (nonatomic) NSMutableArray *blockObjects;
@property (nonatomic, strong) IBOutlet NSView *lockBlockView;

// Status Item
@property (strong, nonatomic) NSStatusItem *statusItem;

- (void)makeLock;
- (IBAction)doUnLock:(id)sender;
- (IBAction)doLock:(id)sender;
- (IBAction)goToURL:(id)sender;
- (IBAction)openPrefs:(id)sender;
- (IBAction)changeDevice:(id)sender;
- (IBAction)setMonitoringUSBDevice:(id)sender;
- (IBAction)setMonitoringBluetooth:(id)sender;

- (void)makeMenu;

- (void)setSecuritySetings:(BOOL)seter withSkip:(BOOL)skip;
- (IBAction)setMenuIcon:(id)sender;

@end
