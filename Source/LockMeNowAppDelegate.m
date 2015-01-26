//
//  LockMeNowAppDelegate.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "LockMeNowAppDelegate.h"

#import "LockManager.h"
#import "JustLock.h"
#import "LoginWindowsLock.h"

#import <ShortcutRecorder/SRRecorderControl.h>
#import <PTHotKey/PTHotKeyCenter.h>
#import <PTHotKey/PTHotKey.h>

#import "iTunesHelper.h"

#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

#include <stdio.h>
#import <Foundation/Foundation.h>
#import <IOKit/usb/IOUSBLib.h>
#import <mach/mach_port.h>
#import "PTUSBHub.h"

#import "NSApplication+MXUtilities.h"

#import <errno.h>
#import <fcntl.h>

IOBluetoothDevice	*m_BluetoothDevice = nil;

@interface LockMeNowAppDelegate() <LockManagerDelegate>

- (void)openImageURLfor:(IKImageView*)_imageView withUrl:(NSURL*)url;
- (void)checkConnectivity;

@property (nonatomic) xpc_connection_t scriptServiceConnection;
@property (nonatomic) IGRUserDefaults *userDefaults;

@property (nonatomic) LockManager *lockManager;

@end

@implementation LockMeNowAppDelegate

- (id) init
{
	if (self= [super init])
	{
		self.userDefaults = [[IGRUserDefaults alloc] init];
	}
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)theNotification
{	
	m_BluetoothDevicePriorStatus = OutOfRange;
	m_BluetoothDevice = nil;
	m_iCurrentUSBDeviceType = -1;
	
	// Setup our connection to the launch item's service.
	// This will start the launch item if it isn't already running.
	
	// Create a connection to the service and send it the message along with our file handles.
	
	// Prep XPC services.
	self.scriptServiceConnection = [self _connectionForServiceNamed:"com.igrsoft.lockmenow.script-service"
										   connectionInvalidHandler:^{
											   self.scriptServiceConnection = NULL;
										   }];
	
	assert(self.scriptServiceConnection != NULL);
	
	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
	assert(message != NULL);
	
	xpc_dictionary_set_uint64(message, "encription", 1);
	
	__weak typeof(self) weakSelf = self;
	
	xpc_connection_send_message_with_reply(self.scriptServiceConnection, message,
										   dispatch_get_main_queue(), ^(xpc_object_t event) {
											   
											   if (xpc_dictionary_get_value(event, "encription") != NULL)
											   {
												   BOOL encription = xpc_dictionary_get_bool(event, "encription");
												   weakSelf.userDefaults.bEncription = encription;
												   if (weakSelf.userDefaults.bEncription)
												   {
													   weakSelf.userDefaults.bAutoPrefs = NO;
												   }
												   
												   DBNSLog(@"Encription: %d", encription);
											   }
										   });
	
	
	m_BluetoothDevice = [NSKeyedUnarchiver unarchiveObjectWithData:self.userDefaults.bluetoothData];
	if (m_BluetoothDevice)
	{
		//Timer interval
		self.p_BluetoothTimerInterval = 2;
		
		[self.bluetoothName setStringValue:[NSString stringWithFormat:@"%@", [m_BluetoothDevice name]]];
	}
	
	if (self.userDefaults.bMonitoringBluetooth)
	{
		[self startMonitoring];
	}
	
	if (self.userDefaults.bUseIconOnMainMenu)
	{
		[self makeMenu];
	}
	
	m_GUIQueue = [[NSOperationQueue alloc] init];
	m_Queue = [[NSOperationQueue alloc] init];
	
	[self.hotKeyControl setCanCaptureGlobalHotKeys:YES];
	
	[[PTHotKeyCenter sharedCenter] unregisterHotKey:self.hotKey];
	PTKeyCombo *keyCombo = [[PTKeyCombo alloc] initWithPlistRepresentation:self.userDefaults.keyCombo];
	
	self.hotKey = [[PTHotKey alloc] initWithIdentifier:kGlobalHotKey
											  keyCombo:keyCombo];
	
	[self.hotKey setTarget: self];
	[self.hotKey setAction: @selector(hotKeyPressed:)];
	
	[[PTHotKeyCenter sharedCenter] registerHotKey:self.hotKey];
	
	NSNumber *kc = @(self.hotKey.keyCombo.keyCode);
	NSNumber *mf = @(self.hotKey.keyCombo.modifierMask);
	
	[self.hotKeyControl setObjectValue:@{@"keyCode": kc, @"modifierFlags": mf}];
	
	NSString* path = [[NSBundle mainBundle] pathForResource: @"off"
													 ofType: @"pdf"];
	
	NSURL* url = [NSURL fileURLWithPath: path];
	
	[self openImageURLfor: self.bluetoothStatus withUrl: url];
	
	[self setupLock];
}

- (void)setupLock
{
	Class lockClass = NULL;
	switch ([self.userDefaults lockingType])
	{
		case LOCK_SCREEN:
			lockClass = [JustLock class];
			break;
		case LOCK_BLOCK:
			//[self makeBlockLock];
			break;
		case LOCK_LOGIN_WINDOW:
		default:
			lockClass = [LoginWindowsLock class];
			break;
	}
	
	self.lockManager = [[lockClass alloc] initWithConnection:self.scriptServiceConnection settings:self.userDefaults];
	self.lockManager.delegate = self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
}

BOOL doNothingAtStart = NO;

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	if (doNothingAtStart)
	{
		doNothingAtStart = NO;
	}
	else
	{
		[self.window makeKeyAndOrderFront:self];
		[self.window center];
	}
}

- (void)applicationWillTerminate:(NSNotification *)theNotification
{
	[m_Queue cancelAllOperations];
	[m_GUIQueue cancelAllOperations];
	[[NSOperationQueue mainQueue] cancelAllOperations];
	
	[self stopMonitoring];
	m_BluetoothDevice = nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if (_lockManager.allowTerminate)
	{
		return NSTerminateNow;
	}
	
	return NSTerminateCancel;
}

#pragma mark - Actions

- (IBAction)goToURL:(id)sender
{
	NSURL *url = [NSURL URLWithString:@"http://igrsoft.com"];
	
	if ([[sender title] isEqualToString:@"Site"])
		url = [NSURL URLWithString:@"http://igrsoft.com" ];
	else if ([[sender title] isEqualToString:@"Twitter"])
		url = [NSURL URLWithString:@"http://twitter.com/#!/iKorich" ];
	else if ([sender tag] == 1)
		url = [NSURL URLWithString:@"http://russianapple.ru" ];
	
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openPrefs:(id)sender
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[self.window makeKeyAndOrderFront: self];
	[self.window makeMainWindow];
	[self.window center];
}

#pragma mark - Shortcut

- (void)hotKeyPressed:(id)sender
{
	//DBNSLog(@"Pressed");
	[self makeLock];
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	PTKeyCombo *keyCombo = [PTKeyCombo keyComboWithKeyCode:[aRecorder keyCombo].code
												 modifiers:[aRecorder cocoaToCarbonFlags:[aRecorder keyCombo].flags]];
	
	if (aRecorder == self.hotKeyControl)
	{
		self.hotKey.keyCombo = keyCombo;
		
		// Re-register the new hot key
		[[PTHotKeyCenter sharedCenter] registerHotKey:self.hotKey];
		self.userDefaults.keyCombo = [keyCombo plistRepresentation];
		[self updateUserSettings:aRecorder];
	}
}

#pragma mark - Lock

- (IBAction)doLock:(id)sender
{
	[self makeLock];
}

- (IBAction)doUnLock:(id)sender
{
	//[self removeSecurityLock];
}

- (void)makeLock
{
	self.userDefaults.bNeedResumeiTunes = NO;
	[self pauseResumeMusic];
	
	[self.lockManager lock];
}

#pragma mark - Preferences

- (IBAction)setMenuIcon:(id)sender
{
	[self makeMenu];
	
	[self updateUserSettings:sender];
}

- (IBAction)setMonitoringBluetooth:(id)sender
{
	if (self.userDefaults.bMonitoringBluetooth)
	{
		[self startMonitoring];
	}
	else
	{
		[self stopMonitoring];
	}
	
	[self updateUserSettings:sender];
}

- (IBAction)setMonitoringUSBDevice:(id)sender
{
	if (self.userDefaults.bMonitoringUSB)
	{
		[self startListeningForDevices];
	}
	else
	{
		[self stopListeningForDevices];
	}
	
	[self updateUserSettings:sender];
}

- (IBAction)toggleStartup:(id)sender
{
	[NSApplication sharedApplication].launchAtLogin = self.userDefaults.bEnableStartup;
	
	[self updateUserSettings:sender];
}

- (IBAction)setLockType:(id)sender
{
	[self setupLock];
	
	[self updateUserSettings:sender];
}

- (IBAction)updateUserSettings:(id)sender
{
	__weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[weakSelf.userDefaults saveUserSettingsWithBluetoothData:nil];
	});
}

#pragma mark - Actions

- (void)pauseResumeMusic
{
	if (self.userDefaults.bPauseiTunes)
	{
		if (!self.userDefaults.bNeedResumeiTunes)
		{
			if ([iTunesHelper isItunesRuning] && [iTunesHelper isMusicPlaing])
			{
				[iTunesHelper playpause];
				self.userDefaults.bNeedResumeiTunes = YES;
			}
		}
		else if (self.userDefaults.bNeedResumeiTunes && self.userDefaults.bResumeiTunes)
		{
			if ([iTunesHelper isItunesRuning] && [iTunesHelper isMusicPaused])
			{
				[iTunesHelper playpause];
				self.userDefaults.bNeedResumeiTunes = NO;
			}
		}
	}
}

#pragma mark - Bluetooth

- (IBAction)changeDevice:(id)sender
{
	IOBluetoothDeviceSelectorController *deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	[deviceSelector runModal];
	
	NSArray *results = [deviceSelector getResults];
	
	if( !results )
	{
		return;
	}
	
	m_BluetoothDevice = results[0];
	
	NSData *deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:m_BluetoothDevice];
	[self.userDefaults saveUserSettingsWithBluetoothData:deviceAsData];
	
	[self.bluetoothName setStringValue:[NSString stringWithFormat:@"%@", [m_BluetoothDevice name]]];
	
	[self checkConnectivity];
}

- (void)checkConnectivity
{
	[m_GUIQueue addOperationWithBlock:^{
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
			[self.spinner startAnimation:self];
		}];
		
		NSString* path = [[NSBundle mainBundle] pathForResource: @"off"
														 ofType: @"pdf"];
		if( m_BluetoothDevicePriorStatus == InRange)
		{
			path = [[NSBundle mainBundle] pathForResource: @"on"
												   ofType: @"pdf"];
		}
		
		NSURL* url = [NSURL fileURLWithPath: path];
		
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			
			[self.spinner stopAnimation:self];
			[self openImageURLfor: self.bluetoothStatus withUrl: url];
		}];
	}];
}

- (BOOL)isInRange
{
	if (m_BluetoothDevice)
	{
		if ([m_BluetoothDevice remoteNameRequest:nil] == kIOReturnSuccess )
		{
			return YES;
		}
	}
	
	return NO;
}

- (void)startMonitoring
{
	if (![m_BluetoothDevice isConnected])
	{
		IOReturn rt = [m_BluetoothDevice openConnection:self];
		m_BluetoothDevicePriorStatus = OutOfRange;
		if (rt != kIOReturnSuccess)
		{
			DBNSLog(@"Can't connect bluetoth device");
		}
	}
	
	m_BluetoothTimer = [NSTimer scheduledTimerWithTimeInterval:self.p_BluetoothTimerInterval
														target:self
													  selector:@selector(handleTimer:)
													  userInfo:nil
													   repeats:YES];
}

- (void)stopMonitoring
{
	m_BluetoothDevicePriorStatus = OutOfRange;
	
	[self checkConnectivity];
	[m_BluetoothDevice closeConnection];
	[m_BluetoothTimer invalidate];
	[m_Queue cancelAllOperations];
}

- (void)handleTimer:(NSTimer *)theTimer
{
	if (![[m_Queue operations] count])
	{
		[m_Queue addOperationWithBlock:^ {
			
			BOOL result = [self isInRange];
			
			if( result )
			{
				if( m_BluetoothDevicePriorStatus == OutOfRange )
				{
					m_BluetoothDevicePriorStatus = InRange;
					[self checkConnectivity];
				}
			}
			else
			{
				if( m_BluetoothDevicePriorStatus == InRange )
				{
					m_BluetoothDevicePriorStatus = OutOfRange;
					[self checkConnectivity];
					[self makeLock];
				}
			}
		}];
	}
}

#pragma mark - GUI

- (void)openImageURLfor:(IKImageView*)_imageView withUrl:(NSURL*)url
{
	[_imageView setBackgroundColor:[NSColor clearColor]];
	
	NSData *contents = [NSData dataWithContentsOfURL:url];
	NSPDFImageRep *pdfRep = [NSPDFImageRep imageRepWithData:contents];
	NSImage *pdfImage = [[NSImage alloc] init];
	[pdfImage addRepresentation: pdfRep];
	
	//convert it from NSImage to CGImageRef
	NSData *imageData = [pdfImage TIFFRepresentation];
	
	CGImageRef imageRef = nil;
	if(imageData)
	{
		CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData,  NULL);
		imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		CFRelease(imageSource);
	}
	
	if (imageRef)
	{
		[_imageView setAutoresizes:YES];
		[_imageView setImage: imageRef
			 imageProperties: nil];
		
		CGImageRelease(imageRef);
	}
}

- (void) makeMenu
{
	if (self.userDefaults.bUseIconOnMainMenu && self.statusItem == nil)
	{
		NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		
		NSStatusBarButton *button = statusItem.button;
		
		button.target = self;
		button.action = @selector(toggleStatus:);
		[button sendActionOn:NSLeftMouseUpMask|NSRightMouseUpMask];
		
		self.statusItem = statusItem;
		
		button.image = [NSImage imageNamed:@"lock"];
		button.appearsDisabled = NO;
		button.toolTip = NSLocalizedString(@"Click to show menu", nil);
		
	}
	else if (!self.userDefaults.bUseIconOnMainMenu && self.statusItem != nil)
	{
		[[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
		self.statusItem = nil;
	}
}

- (void)toggleStatus:(id)sender
{
	[self.statusItem popUpStatusItemMenu:self.statusMenu];
}

#pragma mark - USB

static APPLE_MOBILE_DEVICE APPLE_MOBILE_DEVICES[NUM_APPLE_MOBILE_DEVICES] =
{
	{ "iPhone",					0x1290 },
	{ "iPhone 3G",				0x1292 },
	{ "iPhone 3G[s]",			0x1294 },
	{ "iPhone 4(GSM)",			0x1297 },
	{ "iPhone 4(CDMA)",			0x129c },
	{ "iPhone 4(R2)",			0x129c }, /*not correct*/
	{ "iPhone 4S",				0x12a0 },
	{ "iPhone 5 GSM",			0x12a8 },
	{ "iPhone 5 GLB",			0x12a8 }, /*not correct*/
	{ "iPhone 5C GSM",			0x12a8 }, /*not correct*/
	{ "iPhone 5C GLB",			0x12a8 }, /*not correct*/
	{ "iPhone 5S GSM",			0x12a8 }, /*not correct*/
	{ "iPhone 5S GLB",			0x12a8 }, /*not correct*/
	
	{ "iPod touch 1G",			0x1291 },
	{ "iPod touch 2G",			0x1293 },
	{ "iPod touch 3G",			0x1299 },
	{ "iPod touch 4G",			0x129e },
	{ "iPod touch 5G",			0x12aa },
	
	{ "iPad",					0x129a },
	{ "iPad 2(WiFi)",			0x129f },
	{ "iPad 2(GSM)",			0x12a2 },
	{ "iPad 2(CDMA)",			0x12a3 },
	{ "iPad 3(R2)",				0x12a9 },
	{ "iPad 3(WiFi)",			0x12a4 },
	{ "iPad 3(CDMA)",			0x12a5 },
	{ "iPad 3(4G)",				0x12a6 },
	{ "iPad 4(WiFi)",			0x12ab },
	{ "iPad 4(GSM)",			0x12ab }, /*not correct*/
	{ "iPad 4(GLB)",			0x12ab }, /*not correct*/
	{ "iPad Air(WiFi)",			0x12ab }, /*not correct*/
	{ "iPad Air(GSM)",			0x12ab }, /*not correct*/
	{ "iPad mini(WiFi)",		0x12ab }, /*not correct*/
	{ "iPad mini(GSM)",			0x12ab }, /*not correct*/
	{ "iPad mini(GLB)",			0x12ab }, /*not correct*/
	{ "iPad mini 2(WiFi)",		0x12ab }, /*not correct*/
	{ "iPad mini 2(GSM)",		0x12ab }  /*not correct*/
};

- (void)startListeningForDevices
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
		   selector:@selector(listeningAttachUSBDevice:)
			   name:PTUSBDeviceDidAttachNotification
			 object:PTUSBHub.sharedHub];
	
	[nc addObserver:self
		   selector:@selector(listeningDetachUSBDevice:)
			   name:PTUSBDeviceDidDetachNotification
			 object:PTUSBHub.sharedHub];
}

- (void)stopListeningForDevices
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self
				  name:PTUSBDeviceDidAttachNotification
				object:PTUSBHub.sharedHub];
	
	[nc removeObserver:self
				  name:PTUSBDeviceDidDetachNotification
				object:PTUSBHub.sharedHub];
}

- (void)listeningDetachUSBDevice:(NSNotification *)note
{
	NSInteger _deviceID = [(note.userInfo)[@"DeviceID"] intValue];
	if (m_iUSBDeviceID == _deviceID)
	{
		DBNSLog(@"%@ is disconnected by USB", m_sUSBDeviceName);
		if ([self.userDefaults deviceType] == m_iCurrentUSBDeviceType || [self.userDefaults deviceType] == USB_ALL_DEVICES)
		{
			m_iUSBDeviceID = 0;
			m_sUSBDeviceName = nil;
			[self makeLock];
		}
	}
}

- (void)listeningAttachUSBDevice:(NSNotification *)note
{
	m_iUSBDeviceID = 0;
	m_iCurrentUSBDeviceType = -1;
	
	uint16_t productID = [(note.userInfo)[@"Properties"][@"ProductID"] unsignedShortValue];
	
	for (NSInteger i = NUM_IPHONE_POS; i < NUM_APPLE_MOBILE_DEVICES; ++i)
	{
		APPLE_MOBILE_DEVICE iOSDevice = APPLE_MOBILE_DEVICES[i];
		if (productID == iOSDevice.productID)
		{
			DBNSLog(@"%s is connected by USB", iOSDevice.name);
			m_iUSBDeviceID = [(note.userInfo)[@"DeviceID"] intValue];
			m_sUSBDeviceName = [[NSString alloc] initWithCString:iOSDevice.name encoding:NSUTF8StringEncoding];
			
			if (i < NUM_IPOD_POS) {
				m_iCurrentUSBDeviceType = USB_IPHONE;
			}
			else if (i < NUM_IPAD_POS)
			{
				m_iCurrentUSBDeviceType = USB_IPOD;
			}
			else
			{
				m_iCurrentUSBDeviceType = USB_IPAD;
			}
			
			break;
		}
	}
}

#pragma mark - XPC

- (xpc_connection_t)_connectionForServiceNamed:(const char *)serviceName
					  connectionInvalidHandler:(dispatch_block_t)handler
{
	__block xpc_connection_t serviceConnection =
	xpc_connection_create(serviceName, dispatch_get_main_queue());
	
	if (!serviceConnection)
	{
		NSLog(@"Can't connect to XPC service");
		return (NULL);
	}
	
	NSLog(@"Created connection to XPC service");
	
	xpc_connection_set_event_handler(serviceConnection, ^(xpc_object_t event)
									 {
										 xpc_type_t type = xpc_get_type(event);
										 
										 if (type == XPC_TYPE_ERROR)
										 {
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED)
			{
				// The service has either cancaled itself, crashed, or been
				// terminated.  The XPC connection is still valid and sending a
				// message to it will re-launch the service.  If the service is
				// state-full, this is the time to initialize the new service.
				
				NSLog(@"Interrupted connection to XPC service");
			}
			else if (event == XPC_ERROR_CONNECTION_INVALID)
			{
				// The service is invalid. Either the service name supplied to
				// xpc_connection_create() is incorrect or we (this process) have
				// canceled the service; we can do any cleanup of appliation
				// state at this point.
				NSLog(@"Connection Invalid error for XPC service");
				if (handler)
				{
					handler();
				}
			}
			else
			{
				NSLog(@"Unexpected error for XPC service");
			}
										 }
										 else
										 {
            NSLog(@"Received unexpected event for XPC service");
										 }
									 });
	
	// Need to resume the service in order for it to process messages.
	xpc_connection_resume(serviceConnection);
	return (serviceConnection);
}

#pragma mark - LockManagerDelegate

- (void)unLockSuccess
{
	[self pauseResumeMusic];
}

@end
