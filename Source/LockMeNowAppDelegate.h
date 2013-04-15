//
//  LockMeNowAppDelegate.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <xpc/xpc.h>

@class PTHotKey;
@class IKImageView;
@class IOBluetoothDevice;
@class SRRecorderControl;
@class StartAtLoginController;

extern NSString *kGlobalHotKey;

typedef enum _LockingType {
	LOCK_LOGIN_WINDOW = 0,
	LOCK_SCREEN,
	LOCK_BLOCK,
	} LockingType;

typedef enum _DeviceType {
	USB_ALL_DEVICES = 0,
	USB_IPHONE,
	USB_IPOD,
	USB_IPAD
} DeviceType;

typedef enum _BluetoothStatus {
	InRange = 0,
	OutOfRange
} BluetoothStatus;

typedef struct {
    const char *name;
    uint16_t productID;
} APPLE_MOBILE_DEVICE;

@interface LockMeNowAppDelegate : NSObject <NSApplicationDelegate, NSControlTextEditingDelegate, NSTabViewDelegate> {
	//Interface
    NSStatusItem		*m_statusItem;
	NSApplicationPresentationOptions appPresentationOptions;
	//Lock
	bool				m_bUseIconOnMainMenu;
	bool				m_bPauseiTunes;
	bool				m_bResumeiTunes;
	bool				m_bNeedResumeiTunes;
	bool				m_bAutoPrefs;
	LockingType			m_iLockType;
	
	NSOperationQueue	*m_Queue;
	bool				m_bShouldTerminate;
	
	//Bluetooth
	BluetoothStatus		m_BluetoothDevicePriorStatus;
	bool				m_bMonitoringBluetooth;
	NSTimer				*m_BluetoothTimer;
	
	//USB
	int					m_iUSBDeviceID;
	DeviceType			m_iUSBDeviceType;
	NSString			*m_sUSBDeviceName;
	bool				m_bMonitoringUSB;
	
	//TEst
	NSTimer				*m_TestTimer;
	
	//InApp Purchase
	bool				useAditionalLock;
	bool				isTabsAdded;
	
	//alert
	NSInteger			alertReturnStatus;
	NSString			*m_PriceDeviceLock;
	
	StartAtLoginController *loginController;
}

@property (nonatomic, strong) IBOutlet NSWindow				*window;
@property (nonatomic, strong) IBOutlet SRRecorderControl	*hotKeyControl;
@property (nonatomic, strong) IBOutlet NSMenu				*statusMenu;
@property (nonatomic, strong) IBOutlet NSButton				*btnPurchaseLockByDevice;
@property (nonatomic, strong) IBOutlet NSTabView			*tabView;
@property (nonatomic, strong) IBOutlet NSTabViewItem		*bluetoothTabViewItem;
@property (nonatomic, strong) IBOutlet NSTabViewItem		*usbTabViewItem;

@property (nonatomic, strong) PTHotKey						*hotKey;
@property (nonatomic, strong) IBOutlet IKImageView			*bluetoothStatus;
@property (nonatomic, strong) IBOutlet NSTextField			*bluetoothName;
@property (nonatomic, strong) IBOutlet NSTextField			*timerInterval;
@property (nonatomic) int									p_BluetoothTimerInterval;
@property (nonatomic, strong) IBOutlet NSProgressIndicator	*spinner;
@property (nonatomic) bool	bMonitoring;
@property (nonatomic) bool	bEncription;

@property (nonatomic) NSMutableArray *blockObjects;
@property (nonatomic, strong) IBOutlet NSView *lockBlockView;

- (void) makeLock;
- (IBAction) doUnLock:(id)sender;
- (IBAction) doLock:(id)sender;
- (IBAction) setLockType:(id)sender;
- (IBAction) setiTunesPause:(id)sender;
- (IBAction) setiTunesResume:(id)sender;
- (IBAction) setAutoPrefs:(id)sender;
- (IBAction) goToURL:(id)sender;
- (IBAction) openPrefs:(id)sender;
- (IBAction) changeDevice:(id)sender;
- (IBAction) listenUSBDevice:(id)sender;
- (IBAction) changeUSBDeviceType:(id)sender;
- (IBAction) setMonitoring:(id)sender;
- (IBAction) purchaseLockViaDevise:(id)sender;
- (IBAction) restoreAllPurchases:(id)sender;
- (IBAction) openPurchases:(id)sender;

- (void) makeMenu;
- (void) loadUserSettings;
- (void) saveUserSettings;

- (void) setSecuritySetings:(bool)seter withSkip:(bool)skip;
- (IBAction) setMenuIcon:(id)sender;
@end
