//
//  LockMeNowAppDelegate.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "LockMeNowAppDelegate.h"

#import <ShortcutRecorder/SRRecorderControl.h>
#import <PTHotKey/PTHotKeyCenter.h>
#import <PTHotKey/PTHotKey.h>

#import <ScriptingBridge/ScriptingBridge.h>
#import <IOKit/IOCFBundle.h> 
#import "iTunes.h"

#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

#include <stdio.h>
#import <Foundation/Foundation.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <mach/mach_port.h>
#import "PTUSBHub.h"

#import "InAppPurchaseManager.h"
#import "validatereceipt.h"

NSString *kGlobalHotKey = @"LockMeNowHotKey";
NSString *kIconOnMainMenu = @"IconOnMainMenu";
NSString *kLockType = @"LockType";
NSString *kPauseiTunes = @"PauseiTunes";
NSString *kResumeiTunes = @"ResumeiTunes";
NSString *kAutoScreenSaverPrefs = @"AutoScreenSaverPrefs";
NSString *kBluetoothDevice = @"BluetoothDevice";
NSString *kBluetoothCheckInterval = @"BluetoothCheckInterval";
NSString *kBluetoothMonitoring = @"BluetoothMonitoring";
NSString *kUSBMonitoring = @"USBMonitoring";
NSString *kUSBDeviceType = @"USBDevice";

NSString *global_bundleVersion = @"1.0.0";
NSString *global_bundleIdentifier = @"com.bymaster.lockmenow";

@interface LockMeNowAppDelegate()
- (void)openImageURLfor:(IKImageView*)_imageView withUrl:(NSURL*)url;
- (CGImageRef)nsImageToCGImageRef:(NSImage *)image;
- (void)checkConnectivity;

@end

@implementation LockMeNowAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)theNotification 
{
#if BETA_APP
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setYear:2012];
	[comps setMonth:10];
	[comps setDay:26];
	[comps setHour:12];
	[comps setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"] ];
	
	NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDate *referenceTime = [cal dateFromComponents:comps];
	
	NSDateFormatter *mdf = [[NSDateFormatter alloc] init];
	[mdf setDateFormat:@"yyyy-MM-dd"];
	NSDate *midnight = [mdf dateFromString:[mdf stringFromDate:referenceTime]];
	
	int days = [midnight timeIntervalSinceNow] / (60*60*24) *-1;
	
	if (days > 14) {
		useAditionalLock = false;
	}
#endif
#if USE_VALIDATE_RECEIPT
	
	NSString *receipt = [[[NSBundle mainBundle] appStoreReceiptURL] path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:receipt] == NO)
	{
		DBNSLog(@"_MASReceipt no located. Exit.");
		exit(173);
	}
	else
	{
		 BOOL validRec = validateReceiptAtPath(receipt);
		 
		 if (validRec == NO) {
			 DBNSLog(@"Valid app store receipt not located. Exit.");
			 exit(173);
		 } else {
			 DBNSLog(@"Valid app store receipt located. Launching.");
		 }
	}

	useAditionalLock = false;
	
	NSArray *inApps = obtainInAppPurchases(receipt);
	if (inApps) {
		for (NSDictionary *purchase in inApps) {
			if ([purchase[kReceiptInAppProductIdentifier] isEqualToString:INAPP_ID_DEVICES]) {
				useAditionalLock = true;
			}
		}
	}

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receiveSucceededPurchase:)
												 name:NOTIFICATION_PURCHASE_SUCCEEDED
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receiveFaildPurchase:)
												 name:NOTIFICATION_PURCHASE_FAILED
											   object:nil];
#else
	useAditionalLock = true;
#endif
	
	m_BluetoothDevicePriorStatus = OutOfRange;
	m_BluetoothDevice = nil;
	[self loadUserSettings];
	if (m_bUseIconOnMainMenu) {
		[self makeMenu];
	}
	
	[self updateMenu];
	
	m_Queue = [[NSOperationQueue alloc] init];
	
	[self.hotKeyControl setCanCaptureGlobalHotKeys:YES];
	
	[[PTHotKeyCenter sharedCenter] unregisterHotKey:self.hotKey];
	id keyComboPlist = [[NSUserDefaults standardUserDefaults] objectForKey:kGlobalHotKey];
	PTKeyCombo *keyCombo = [[PTKeyCombo alloc] initWithPlistRepresentation:keyComboPlist];
	
	self.hotKey = [[PTHotKey alloc] initWithIdentifier:kGlobalHotKey
											  keyCombo:keyCombo];
	
	[self.hotKey setTarget: self];
	[self.hotKey setAction: @selector(hotKeyPressed:)];
	
	[[PTHotKeyCenter sharedCenter] registerHotKey:self.hotKey];
	
	NSNumber *kc = @(self.hotKey.keyCombo.keyCode);
	NSNumber *mf = @(self.hotKey.keyCombo.modifierMask);
	
	[self.hotKeyControl setObjectValue:@{@"keyCode": kc,
	 @"modifierFlags": mf}];
	
	NSString* path = [[NSBundle mainBundle] pathForResource: @"off"
													 ofType: @"pdf"];
	
	NSURL* url = [NSURL fileURLWithPath: path];
	
	[self openImageURLfor: self.bluetoothStatus withUrl: url];
	
	m_bNeedResumeiTunes = false;
	m_bShouldTerminate = true;
	m_bEncription = false;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0ul);
	dispatch_async(queue, ^{
		m_bEncription = [self checkEncryptionComplete];
	});
}

- (void)awakeFromNib {
	
	[super awakeFromNib];
}

bool doNothingAtStart = false;

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	if (doNothingAtStart) {
		doNothingAtStart = false;
	} else {
		[self.window makeKeyAndOrderFront:self];
		[self.window center];
	}
}

- (void)applicationWillTerminate:(NSNotification *)theNotification 
{
	[self saveUserSettings];
	[self stopMonitoring];
	m_BluetoothDevice = nil;
	[[NSUserDefaults standardUserDefaults] setObject:[self.hotKey.keyCombo plistRepresentation] 
											  forKey:kGlobalHotKey];
}

-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (m_bShouldTerminate) {
        return NSTerminateNow;
    }
    return NSTerminateCancel;
}

#pragma mark - Actions

- (IBAction) goToURL:(id)sender
{
	@autoreleasepool {
	
		NSURL *url = [NSURL URLWithString:@"http://igrsoft.com"];
		
		if ([[sender title] isEqualToString:@"Site"])
			url = [NSURL URLWithString:@"http://igrsoft.com" ];
		else if ([[sender title] isEqualToString:@"Twitter"])
			url = [NSURL URLWithString:@"http://twitter.com/#!/iKorich" ];
		else if ([sender tag] == 1)
			url = [NSURL URLWithString:@"http://russianapple.ru" ];
		
		[[NSWorkspace sharedWorkspace] openURL:url];
	
	}
}

- (IBAction) openPrefs:(id)sender
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
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	PTKeyCombo *keyCombo = [PTKeyCombo keyComboWithKeyCode:[aRecorder keyCombo].code
												 modifiers:[aRecorder cocoaToCarbonFlags:[aRecorder keyCombo].flags]];
	
	if (aRecorder == self.hotKeyControl) {
		self.hotKey.keyCombo = keyCombo;
		
		// Re-register the new hot key
		[[PTHotKeyCenter sharedCenter] registerHotKey:self.hotKey];
		[defaults setObject:[keyCombo plistRepresentation] forKey:kGlobalHotKey];
	}
	
	[defaults synchronize];
}


#pragma mark - Lock

- (IBAction) doLock:(id)sender
{
	[self makeLock];
}

- (IBAction) doUnLock:(id)sender
{
	[self removeSecurityLock];
}

- (IBAction) setLockType:(id)sender
{
	m_iLockType = [sender selectedRow];
}

- (IBAction) setiTunesPause:(id)sender
{
	NSButton *btn = sender;
	m_bPauseiTunes = [btn state];
}

- (IBAction) setiTunesResume:(id)sender
{
	NSButton *btn = sender;
	m_bResumeiTunes = [btn state];
}

- (IBAction) setAutoPrefs:(id)sender
{
	NSButton *btn = sender;
	m_bAutoPrefs = [btn state];
}

- (void) makeLock
{
	m_bNeedResumeiTunes = false;
	[self pauseResumeMusic];
	
	switch (m_iLockType) {
		case LOCK_SCREEN:
			[self makeJustLock];
			break;
		case LOCK_BLOCK:
			[self makeBlockLock];
			break;
		case LOCK_LOGIN_WINDOW:	
		default:
			[self makeLoginWindowsLock];
			break;
	}
}

- (void) makeLoginWindowsLock
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(receiveBecomeActiveNotification:)
															   name:NSWorkspaceSessionDidBecomeActiveNotification
															 object:NULL];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(receiveResignActiveNotification:)
															   name:NSWorkspaceSessionDidResignActiveNotification
															 object:NULL];
	
	[[NSTask launchedTaskWithLaunchPath:@"/bin/bash"
							  arguments:@[@"-c", @"exec \"/System/Library/CoreServices/Menu Extras/user.menu/Contents/Resources/CGSession\" -suspend"]]
	 waitUntilExit];
}

- (void) makeJustLock
{
	bool m_bNeedBlock = false;
	
	if (!m_bEncription) {
		m_bNeedBlock = ![self askPassword];
	}
	
	if (m_bNeedBlock)
	{
		DBNSLog(@"Set Security Lock");
		[self setSecuritySetings:YES withSkip:m_bNeedBlock];
	}
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(setScreenLockActive:)
															name:@"com.apple.screenIsLocked"
														  object:NULL];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(setScreenLockInActive:)
															name:@"com.apple.screenIsUnlocked"
														  object:NULL];
	
	io_registry_entry_t r =	IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
	if(!r) return;
	IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
	IOObjectRelease(r);
}

- (void) makeBlockLock
{
	if (_blockObjects != nil) {
		return;
	}
	m_bShouldTerminate = false;
    _blockObjects = [[NSMutableArray alloc] init];
    
    NSRect screenRect;
    NSArray *screenArray = [NSScreen screens];
    unsigned screenCount = [screenArray count];
    unsigned index  = 0;
    
    for (index = 0; index < screenCount; index++)
    {
        NSScreen *screen = screenArray[index];
        screenRect = [screen frame];
        
        
        NSWindow *blocker = [[NSWindow alloc] initWithContentRect:screenRect
														styleMask:0
														  backing:NSBackingStoreBuffered
															defer:NO
														   screen:[NSScreen mainScreen]];
        [blocker setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"lock-bg"]]];
        [blocker setIsVisible:YES];
        [blocker setLevel:NSScreenSaverWindowLevel];
        [blocker makeKeyAndOrderFront:nil];
        [_blockObjects insertObject:blocker
							atIndex:index];
    }
    
    @try {
		NSApplication *currentApp = [NSApplication sharedApplication];
		appPresentationOptions = [currentApp presentationOptions];
        NSApplicationPresentationOptions options = NSApplicationPresentationHideDock
													+ NSApplicationPresentationHideMenuBar
													+ NSApplicationPresentationDisableForceQuit
													+ NSApplicationPresentationDisableProcessSwitching;
        [currentApp setPresentationOptions:options];
    }
    @catch(NSException * exception) {
        DBNSLog(@"Error.  Make sure you have a valid combination of options.");
    }
	
	NSWindow *firstBlocker = (NSWindow*)_blockObjects[0];
	[firstBlocker setContentView:_lockBlockView];
}

- (void)setScreenLockActive:(NSNotification *)aNotification
{
	DBNSLog(@"Screen Lock");
}

- (void)setScreenLockInActive:(NSNotification *)aNotification
{
	DBNSLog(@"Screen Unlock");
	[self removeSecurityLock];
}

- (void)receiveBecomeActiveNotification:(NSNotification *)aNotification
{
	DBNSLog(@"Logo in");
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self
																  name:NSWorkspaceSessionDidBecomeActiveNotification
																object:NULL];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self
																  name:NSWorkspaceSessionDidResignActiveNotification
																object:NULL];
	
	[self pauseResumeMusic];
}

- (void)receiveResignActiveNotification:(NSNotification *)aNotification
{
	DBNSLog(@"Logo out");
}

- (void) pauseResumeMusic
{
	if (m_bPauseiTunes) {
		if (!m_bNeedResumeiTunes) {
			if (ProcessIsRunningWithBundleID((CFStringRef)@"com.apple.iTunes", 0)) {
				iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
				
				if ([iTunes playerState] == iTunesEPlSPlaying) {
					[iTunes playpause];
					m_bNeedResumeiTunes = true;
				}
			}
		}
		else if (m_bNeedResumeiTunes && m_bResumeiTunes)
		{
			if (ProcessIsRunningWithBundleID((CFStringRef)@"com.apple.iTunes", 0)) {
				iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
				
				if ([iTunes playerState] == iTunesEPlSPaused || [iTunes playerState] == iTunesEPlSStopped) {
					[iTunes playpause];
					m_bNeedResumeiTunes = false;
				}
			}
		}
	}
}

- (void)removeSecurityLock
{	
	[self pauseResumeMusic];
	
	bool m_bNeedBlock = false;
	
	if (!m_bEncription) {
		m_bNeedBlock = ![self askPassword];
	}
	
	if (m_bNeedBlock)
	{
		DBNSLog(@"Remove Security Lock");
		[self setSecuritySetings:NO withSkip:m_bNeedBlock];
	}
	
	switch (m_iLockType) {
		case LOCK_SCREEN:
			[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
																	   name:@"com.apple.screenIsLocked"
																	 object:NULL];
			[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
																	   name:@"com.apple.screenIsUnlocked"
																	 object:NULL];
			break;
		case LOCK_BLOCK:
			for(NSWindow *blocker in _blockObjects) {
				[blocker orderOut:self];
				DBNSLog(@"closing blocker");
			}
			
			_blockObjects = nil;
			
			if (!m_bShouldTerminate) {
				NSApplication *currentApp = [NSApplication sharedApplication];
				[currentApp setPresentationOptions:appPresentationOptions];
				m_bShouldTerminate = true;
			}
			break;
		case LOCK_LOGIN_WINDOW:
		default:
			break;
	}
}

- (BOOL)askPassword
{
	bool isPassword = (bool)CFPreferencesGetAppIntegerValue(CFSTR("askForPassword"), CFSTR("com.apple.screensaver"), nil);
	
	return isPassword;
}

- (bool)checkEncryptionComplete {
	NSString *pathToMyScript = [[NSBundle mainBundle] pathForResource:@"filevault_2_encryption_check_extension_attribute" ofType:@"sh"];
	NSTask *server = [NSTask new];
	[server setLaunchPath:@"/bin/sh"];
	[server setArguments:@[pathToMyScript]];
	[server setCurrentDirectoryPath:[[NSBundle mainBundle] bundlePath]];
	
	NSPipe *outputPipe = [NSPipe pipe];
	[server setStandardInput:[NSPipe pipe]];
	[server setStandardOutput:outputPipe];
	
	[server launch];
	[server waitUntilExit]; // Alternatively, make it asynchronous.
	
	NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
	NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding]; // Autorelease optional, depending on usage.
	
	if ([outputString isEqualToString:@"<result>FileVault 2 Encryption Complete</result>"]) {
		return true;
	}
	
	return false;
}

- (void) setSecuritySetings:(bool)seter withSkip:(bool)skip
{
	if (!m_bAutoPrefs) {
		return;
	}
	
	BOOL success = true;
	
	if (!skip) {
		NSNumber *val = @(seter);
		CFPreferencesSetValue(CFSTR("askForPassword"), (__bridge CFPropertyListRef) val,
							  CFSTR("com.apple.screensaver"),
							  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		success = CFPreferencesSynchronize(CFSTR("com.apple.screensaver"),
										   kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		
		CFPreferencesSetValue(CFSTR("askForPasswordDelay"), (__bridge CFPropertyListRef) @0,
							  CFSTR("com.apple.screensaver"),
							  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		success = CFPreferencesSynchronize(CFSTR("com.apple.screensaver"),
										   kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		
		// Notify login process
		// not sure this does or why it must be called...anyone? (DBR)
		if (success) {
			CFMessagePortRef port = CFMessagePortCreateRemote(NULL, CFSTR("com.apple.loginwindow.notify"));
			success = (CFMessagePortSendRequest(port, 500, 0, 0, 0, 0, 0) == kCFMessagePortSuccess);
			CFRelease(port);
		}
	}
}

- (IBAction) setMenuIcon:(id)sender
{
	NSButton *btn = sender;
	m_bUseIconOnMainMenu = [btn state];
	[self makeMenu];
}

#pragma mark - deafuts
+ (void) initialize
{
    // Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	defaultValues[kIconOnMainMenu] = @YES;
	defaultValues[kLockType] = @(LOCK_LOGIN_WINDOW);
	defaultValues[kPauseiTunes] = @YES;
	defaultValues[kResumeiTunes] = @YES;
	defaultValues[kAutoScreenSaverPrefs] = @NO;

	defaultValues[kBluetoothCheckInterval] = @60;
	defaultValues[kBluetoothMonitoring] = @NO;
	defaultValues[kUSBMonitoring] = @NO;
	defaultValues[kUSBDeviceType] = @(USB_ALL_DEVICES);
	
    // Register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    //DBNSLog(@"registered defaults: %@", defaultValues);
}

-(void) loadUserSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	m_bUseIconOnMainMenu = [[defaults objectForKey:kIconOnMainMenu] boolValue];
	m_iLockType = [[defaults objectForKey:kLockType] intValue];
	m_bPauseiTunes = [[defaults objectForKey:kPauseiTunes] boolValue];
	m_bResumeiTunes = [[defaults objectForKey:kResumeiTunes] boolValue];
	m_bAutoPrefs = [[defaults objectForKey:kAutoScreenSaverPrefs] boolValue];
	
	if (useAditionalLock) {
		NSData *deviceAsData = [defaults objectForKey:kBluetoothDevice];
		if( [deviceAsData length] > 0 )
		{
			m_BluetoothDevice = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
			if (m_BluetoothDevice) {
				if (![m_BluetoothDevice isConnected])
				{
					IOReturn rt = [m_BluetoothDevice openConnection:self];
					if (rt != kIOReturnSuccess) {
						DBNSLog(@"Can't connect bluetoth device");
					}
				}
				[self.bluetoothName setStringValue:[NSString stringWithFormat:@"%@", [m_BluetoothDevice name]]];
			}
		}
		
		//Timer interval
		_p_BluetoothTimerInterval = [[defaults stringForKey:kBluetoothCheckInterval] intValue];
		
		// Monitoring enabled
		m_bMonitoringBluetooth = [defaults boolForKey:kBluetoothMonitoring];
		m_bMonitoringUSB = [defaults boolForKey:kUSBMonitoring];
	}
}

-(void) saveUserSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    [defaults setBool:m_bUseIconOnMainMenu forKey:kIconOnMainMenu];
	[defaults setInteger:m_iLockType forKey:kLockType];
	[defaults setBool:m_bPauseiTunes forKey:kPauseiTunes];
	[defaults setBool:m_bResumeiTunes forKey:kResumeiTunes];
	[defaults setBool:m_bAutoPrefs forKey:kAutoScreenSaverPrefs];
	
	if (useAditionalLock) {
		// Monitoring enabled
		[defaults setBool:m_bMonitoringBluetooth forKey:kBluetoothMonitoring];
		
		// Timer interval
		[defaults setInteger:_p_BluetoothTimerInterval forKey:kBluetoothCheckInterval];
		
		// Device
		if( m_BluetoothDevice ) {
			NSData *deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:m_BluetoothDevice];
			[defaults setObject:deviceAsData forKey:kBluetoothDevice];
		}
		
		[defaults setBool:m_bMonitoringUSB forKey:kUSBMonitoring];
		[defaults setInteger:m_iUSBDeviceType forKey:kUSBDeviceType];
	}
	
	[defaults synchronize];
}

int ProcessIsRunningWithBundleID(CFStringRef inBundleID, ProcessSerialNumber* outPSN) 
{ 
	int theResult = 0; 
	
	ProcessSerialNumber thePSN = {0, kNoProcess}; 
	OSErr theError = noErr; 
	do { 
		theError = GetNextProcess(&thePSN); 
		if(theError == noErr) 
		{ 
			CFDictionaryRef theInfo = NULL; 
			theInfo = ProcessInformationCopyDictionary(&thePSN, kProcessDictionaryIncludeAllInformationMask); 
			if(theInfo) 
			{ 
				CFStringRef theBundleID = CFDictionaryGetValue(theInfo, kIOBundleIdentifierKey); 
				if(theBundleID) 
				{ 
					if(CFStringCompare(theBundleID, inBundleID, 0) == kCFCompareEqualTo) 
					{ 
						theResult = 1; 
					} 
				} 
				CFRelease(theInfo); 
			} 
		} 
	} while((theError != procNotFound) && (theResult == 0)); 
	
	if(theResult && outPSN) 
	{ 
		*outPSN = thePSN; 
	} 
	
	return theResult; 
} 

#pragma mark - Bluetooth

- (IBAction)changeDevice:(id)sender
{
	IOBluetoothDeviceSelectorController *deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	[deviceSelector runModal];
	
	NSArray *results = [deviceSelector getResults];
	
	if( !results )
		return;
	
	m_BluetoothDevice = results[0];
	
	[self.bluetoothName setStringValue:[NSString stringWithFormat:@"%@", [m_BluetoothDevice name]]];
	
	[self checkConnectivity];
}

- (void)checkConnectivity
{
	[m_Queue addOperationWithBlock:^{
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
	if (useAditionalLock) {
		if( m_BluetoothDevice && [m_BluetoothDevice remoteNameRequest:nil] == kIOReturnSuccess )
			return true;
	}
	
	return false;
}

- (void)startMonitoring
{
	if (useAditionalLock) {
		m_BluetoothTimer = [NSTimer scheduledTimerWithTimeInterval:_p_BluetoothTimerInterval
															target:self
														  selector:@selector(handleTimer:)
														  userInfo:nil
														   repeats:YES];
		[self handleTimer:m_BluetoothTimer];
	}
}

- (void)stopMonitoring
{
	if (useAditionalLock) {
		[m_BluetoothTimer invalidate];
	}
}

- (void)handleTimer:(NSTimer *)theTimer
{
	if (useAditionalLock) {
		if( [self isInRange] )
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
	}
}

- (IBAction) setMonitoring:(id)sender
{
	if (useAditionalLock) {
		NSButton *btn = sender;
		m_bMonitoringBluetooth = [btn state] == NSOnState ? TRUE : FALSE;
		if (m_bMonitoringBluetooth)
		{
			[self startMonitoring];
		}
		else
		{
			[self stopMonitoring];
		}
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	if (useAditionalLock) {
		_p_BluetoothTimerInterval = [[self.timerInterval stringValue] intValue];
		[self.timerInterval resignFirstResponder];
		[self saveUserSettings];
		[self stopMonitoring];
		[self startMonitoring];
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
    CGImageRef image = [self nsImageToCGImageRef:pdfImage];
	
	if (image)
    {
        [_imageView setImage: image
             imageProperties: nil];
		
		CGImageRelease(image);
    }
}

- (CGImageRef)nsImageToCGImageRef:(NSImage *)image {
	
    NSData *imageData = [image TIFFRepresentation];
	
    CGImageRef imageRef = nil;
    if(imageData)
    {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData,  NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
	
	return imageRef;
}

- (void) makeMenu
{
	if (m_bUseIconOnMainMenu && m_statusItem == nil) {
		m_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
		[m_statusItem setMenu:self.statusMenu];
		NSImage *itemImage = [[NSImage alloc]
							  initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"lock" ofType:@"tiff"]];
		
		[m_statusItem setImage: itemImage];
		[m_statusItem setHighlightMode:YES];
		
	}
	else if (!m_bUseIconOnMainMenu && m_statusItem != nil)
	{
		[[NSStatusBar systemStatusBar] removeStatusItem:m_statusItem];
		m_statusItem = nil;
	}
}

- (void) updateMenu
{
	NSArray *arr = [self.statusMenu itemArray];
	for (NSMenuItem *item in arr) {
		if ([[item title] isEqualToString:@"Purchase"]) {
			NSArray *submenuItems = [[item submenu] itemArray];
			for (NSMenuItem *submenuItem in submenuItems) {
				if ([item tag] == 99) {
					[item setEnabled:!useAditionalLock];
				}
			}
		}
	}
}

#pragma mark - USB

static APPLE_MOBILE_DEVICE APPLE_MOBILE_DEVICES[NUM_APPLE_MOBILE_DEVICES] = {
    { "iPhone",					0x1290 },
    { "iPhone 3G",				0x1292 },
    { "iPhone 3G[s]",			0x1294 },
    { "iPhone 4(GSM)",			0x1297 },
    { "iPhone 4(CDMA)",			0x129c },
	{ "iPhone 4(R2)",			0x129c }, /*not correct*/
    { "iPhone 4S",				0x12a0 },
	{ "iPhone 5 GSM",			0x12a8 },
	{ "iPhone 5 GLB",			0x12a8 }, /*not correct*/
    { "iPod touch 1G",			0x1291 },
    { "iPod touch 2G",			0x1293 },
    { "iPod touch 3G",			0x1299 },
    { "iPod touch 4G",			0x129e },
	{ "iPod touch 5G",			0x129e }, /*not correct*/
    { "iPad",					0x129a },
    { "iPad 2(WiFi)",			0x129f },
    { "iPad 2(GSM)",			0x12a2 },
    { "iPad 2(CDMA)",			0x12a3 },
	{ "iPad 3(R2)",				0x12a9 },
	{ "iPad 3(WiFi)",			0x12a4 },
	{ "iPad 3(CDMA)",			0x12a5 },
	{ "iPad 3(4G)",				0x12a6 },
	{ "iPad 4(WiFi)",			0x12ab }, /*not correct*/
	{ "iPad 4(GSM)",			0x12ab }, /*not correct*/
	{ "iPad 4(GLB)",			0x12ab }, /*not correct*/
	{ "iPad mini(WiFi)",		0x12ab }, /*not correct*/
	{ "iPad mini(GSM)",			0x12ab }, /*not correct*/
	{ "iPad mini(GLB)",			0x12ab }  /*not correct*/
};

- (void)startListeningForDevices {
	if (useAditionalLock) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		[nc addObserver:self selector:@selector(ListeningAttachUSBDevice:) name:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub];
		[nc addObserver:self selector:@selector(ListeningDetachUSBDevice:) name:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub];
	}
}

- (void)stopListeningForDevices {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc removeObserver:self name:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub];
	[nc removeObserver:self name:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub];
}

- (void) ListeningDetachUSBDevice: (NSNotification *)note
{
	int _deviceID = [(note.userInfo)[@"DeviceID"] intValue];
	if (m_iUSBDeviceID == _deviceID) {
		DBNSLog(@"%@ is disconnected by USB", m_sUSBDeviceName);
		m_iUSBDeviceID = 0;
		m_sUSBDeviceName = nil;
		[self makeLock];
	}
}

- (void) ListeningAttachUSBDevice: (NSNotification *)note
{
	uint16_t productID = [(note.userInfo)[@"Properties"][@"ProductID"] unsignedShortValue];
	switch (m_iUSBDeviceType) {
		case USB_ALL_DEVICES:
		{
			for (int i = NUM_IPHONE_POS; i < NUM_APPLE_MOBILE_DEVICES; ++i) {
				APPLE_MOBILE_DEVICE iOSDevice = APPLE_MOBILE_DEVICES[i];
				if (productID == iOSDevice.productID) {
					DBNSLog(@"%s is connected by USB", iOSDevice.name);
					m_iUSBDeviceID = [(note.userInfo)[@"DeviceID"] intValue];
					m_sUSBDeviceName = [[NSString alloc] initWithCString:iOSDevice.name encoding:NSUTF8StringEncoding];
					[self removeSecurityLock];
					break;
				}
			}
		}
			break;
		case USB_IPHONE:
		{
			for (int i = NUM_IPHONE_POS; i < NUM_IPOD_POS; ++i) {
				APPLE_MOBILE_DEVICE iOSDevice = APPLE_MOBILE_DEVICES[i];
				if (productID == iOSDevice.productID) {
					DBNSLog(@"%s is connected by USB", iOSDevice.name);
					m_iUSBDeviceID = [(note.userInfo)[@"DeviceID"] intValue];
					m_sUSBDeviceName = [[NSString alloc] initWithCString:iOSDevice.name encoding:NSUTF8StringEncoding];
					[self removeSecurityLock];
					break;
				}
			}
		}
			break;
		case USB_IPOD:
		{
			for (int i = NUM_IPOD_POS; i < NUM_IPAD_POS; ++i) {
				APPLE_MOBILE_DEVICE iOSDevice = APPLE_MOBILE_DEVICES[i];
				if (productID == iOSDevice.productID) {
					DBNSLog(@"%s is connected by USB", iOSDevice.name);
					m_iUSBDeviceID = [(note.userInfo)[@"DeviceID"] intValue];
					m_sUSBDeviceName = [[NSString alloc] initWithCString:iOSDevice.name encoding:NSUTF8StringEncoding];
					[self removeSecurityLock];
					break;
				}
			}
		}
			break;
		case USB_IPAD:
		{
			for (int i = NUM_IPAD_POS; i < NUM_APPLE_MOBILE_DEVICES; ++i) {
				APPLE_MOBILE_DEVICE iOSDevice = APPLE_MOBILE_DEVICES[i];
				if (productID == iOSDevice.productID) {
					DBNSLog(@"%s is connected by USB", iOSDevice.name);
					m_iUSBDeviceID = [(note.userInfo)[@"DeviceID"] intValue];
					m_sUSBDeviceName = [[NSString alloc] initWithCString:iOSDevice.name encoding:NSUTF8StringEncoding];
					[self removeSecurityLock];
					break;
				}
			}
		}
			break;
		default:
			break;
	}
}

- (IBAction) listenUSBDevice:(id)sender
{
	if (useAditionalLock) {
		NSButton *btn = sender;
		m_bMonitoringUSB = [btn state] == NSOnState ? TRUE : FALSE;
		if (m_bMonitoringUSB)
		{
			[self startListeningForDevices];
		}
		else
		{
			[self stopListeningForDevices];
		}
	}	
}

- (IBAction) changeUSBDeviceType:(id)sender
{
	NSMatrix *matrix = sender;
	m_iUSBDeviceType = [matrix selectedRow];
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	int tabSelection = [[tabViewItem identifier] intValue];
	if (tabSelection == 1 || tabSelection == 4)
	{
		return YES;
	}
	else
	{
		if (useAditionalLock)
			return YES;
		else
		{
#if (USE_VALIDATE_RECEIPT)
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
			[alert addButtonWithTitle:NSLocalizedString(@"Buy", @"Buy")];
			[alert addButtonWithTitle:NSLocalizedString(@"Restore", @"Restore")];
			[alert setMessageText:NSLocalizedString(@"Warning", @"Warning")];
			
			[alert setInformativeText:NSLocalizedString(@"Would you like to buy it?", @"Would you like to buy it")];
			
			[self startAlert:alert selector:@selector(closeAlert:returnCode:contextInfo:)];
#endif
			return NO;
		}
	}
	
	return NO;
}

#pragma mark - Purchase
- (IBAction) purchaseLockViaDevise:(id)sender
{
#if (USE_VALIDATE_RECEIPT)
	if ([[InAppPurchaseManager sharedManager] canMakePurchases]) {
		[[InAppPurchaseManager sharedManager] purchase:INAPP_ID_DEVICES];
	} else {
		DBNSLog(@"InApp Purchase not supported");
	}
#endif
}

- (IBAction)restoreAllPurchases:(id)sender {
	[[InAppPurchaseManager sharedManager] restoreCompletedTransactions];
}

- (void) receiveSucceededPurchase:(NSNotification *) notification
{
#if (USE_VALIDATE_RECEIPT)
	SKPaymentTransaction *transaction = [notification userInfo][KEY_TRANSACTION];
	NSString *inAppId = [notification userInfo][KEY_PRODUCT_ID];
	
	NSString *textAlert = @"";
	bool useAlert = true;
	switch (transaction.transactionState) {
		case SKPaymentTransactionStateRestored:
			if ([inAppId isEqualToString:INAPP_ID_DEVICES]) {
				useAditionalLock = true;
			}
			textAlert = @"You have successfully restored Lock By Device";
			useAlert = true;
			break;
		case SKPaymentTransactionStatePurchased:
			if ([inAppId isEqualToString:INAPP_ID_DEVICES]) {
				useAditionalLock = true;
			}
			textAlert = @"You have successfully purchased Lock By Device";
			useAlert = true;
			break;
		default:
			useAlert = false;
			break;
	}
	
	if (useAditionalLock) {
		if (m_bMonitoringBluetooth)
		{
			[self startMonitoring];
		}
		if (m_bMonitoringUSB) {
			[self startListeningForDevices];
		}
	}
	
	if (useAlert) {
		DBNSLog(@"InApp %@ successfully purchased", inAppId);
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
		[alert setMessageText:NSLocalizedString(@"Congrats!", @"Congrats")];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert setInformativeText:textAlert];
		[alert runModal];
	}
	else
	{
		DBNSLog(@"InApp %@ successfully restored", inAppId);
	}
#endif
	[self updateMenu];
}

- (void) receiveFaildPurchase:(NSNotification *) notification
{
	NSString *inAppId = [notification userInfo][KEY_PRODUCT_ID];
	
	if ([inAppId isEqualToString:INAPP_ID_DEVICES]) {
		useAditionalLock = false;
	}
	
	DBNSLog(@"Can't process purchase %@: %@", inAppId, [notification userInfo][KEY_TRANSACTION_ERROR]);
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
	[alert setMessageText:NSLocalizedString(@"Something wrong!", @"Something wrong!")];
	[alert setAlertStyle:NSInformationalAlertStyle];
	[alert setInformativeText:@"Can't process purchase, please, try later."];
	[alert runModal];
}

#pragma mark - Alert / Panel

- (void) startAlert:(NSAlert*) alert selector:(SEL)alertSelector
{
	alertReturnStatus = -1;
	
	[alert setShowsHelp:NO];
	[alert setShowsSuppressionButton:NO];
	[alert beginSheetModalForWindow:self.window
					  modalDelegate:self
					 didEndSelector:alertSelector
						contextInfo:nil];
	
	NSModalSession session = [NSApp beginModalSessionForWindow:[alert window]];
	for (;;) {
		// alertReturnStatus will be set in alertDidEndSheet:returnCode:contextInfo:
		if(alertReturnStatus != -1)
			break;
		
		// Execute code on DefaultRunLoop
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate distantFuture]];
		
		// Break the run loop if sheet was closed
		if ([NSApp runModalSession:session] != NSRunContinuesResponse
			|| ![[alert window] isVisible])
			break;
		
		// Execute code on DefaultRunLoop
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate distantFuture]];
		
	}
	[NSApp endModalSession:session];
	[NSApp endSheet:[alert window]];
}

- (void)closeAlert:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	DBNSLog(@"clicked %d button\n", returnCode);
	if (returnCode == NSAlertSecondButtonReturn) {
		[[InAppPurchaseManager sharedManager] purchase:INAPP_ID_DEVICES];
	}
	else if (returnCode == NSAlertThirdButtonReturn) {
		[[InAppPurchaseManager sharedManager] restoreCompletedTransactions];
	}
    // make the returnCode publicly available after closing the sheet
    alertReturnStatus = returnCode;
}

@end
