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

#include <stdio.h>
#import <Foundation/Foundation.h>
#import <IOKit/usb/IOUSBLib.h>
#import <mach/mach_port.h>

#import "StartAtLoginController.h"

#import <errno.h>
#import <fcntl.h>

NSString *kGlobalHotKey = @"LockMeNowHotKey";
NSString *kIconOnMainMenu = @"IconOnMainMenu";
NSString *kLockType = @"LockType";
NSString *kPauseiTunes = @"PauseiTunes";
NSString *kResumeiTunes = @"ResumeiTunes";
NSString *kAutoScreenSaverPrefs = @"AutoScreenSaverPrefs";

NSString *global_bundleVersion = @"1.0.0";
NSString *global_bundleIdentifier = @"com.bymaster.lockmenow";

@interface LockMeNowAppDelegate()

int ProcessIsRunningWithBundleID(CFStringRef inBundleID, ProcessSerialNumber* outPSN);

@property (nonatomic) xpc_connection_t scriptServiceConnection;

@end

@implementation LockMeNowAppDelegate

- (xpc_connection_t) _connectionForServiceNamed:(const char *)serviceName
                       connectionInvalidHandler:(dispatch_block_t)handler
{
    __block xpc_connection_t serviceConnection =
	xpc_connection_create(serviceName, dispatch_get_main_queue());
	
    if (!serviceConnection) {
        NSLog(@"Can't connect to XPC service");
        return (NULL);
    }
	
    NSLog(@"Created connection to XPC service");
	
    xpc_connection_set_event_handler(serviceConnection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
		
        if (type == XPC_TYPE_ERROR) {
			
            if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                // The service has either cancaled itself, crashed, or been
                // terminated.  The XPC connection is still valid and sending a
                // message to it will re-launch the service.  If the service is
                // state-full, this is the time to initialize the new service.
				
                NSLog(@"Interrupted connection to XPC service");
            } else if (event == XPC_ERROR_CONNECTION_INVALID) {
                // The service is invalid. Either the service name supplied to
                // xpc_connection_create() is incorrect or we (this process) have
                // canceled the service; we can do any cleanup of appliation
                // state at this point.
                NSLog(@"Connection Invalid error for XPC service");
                xpc_release(serviceConnection);
                if (handler) {
                    handler();
                }
            } else {
                NSLog(@"Unexpected error for XPC service");
            }
        } else {
            NSLog(@"Received unexpected event for XPC service");
        }
    });
	
    // Need to resume the service in order for it to process messages.
    xpc_connection_resume(serviceConnection);
    return (serviceConnection);
}

- (void)applicationDidFinishLaunching:(NSNotification *)theNotification 
{
	m_bNeedResumeiTunes = false;
	m_bShouldTerminate = true;
	self.bEncription = false;
	
	loginController = [[StartAtLoginController alloc] init];
	[loginController setBundle:[NSBundle bundleWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Library/LoginItems/LaunchAtLoginHelper.app"]]];
	
	// Setup our connection to the launch item's service.
	// This will start the launch item if it isn't already running.
	
	// Create a connection to the service and send it the message along with our file handles.
	
	// Prep XPC services.
	self.scriptServiceConnection = [self _connectionForServiceNamed:"com.bymaster.lockmenow.script-service"
                                            connectionInvalidHandler:^{
												self.scriptServiceConnection = NULL;
											}];
    
    assert(self.scriptServiceConnection != NULL);
	
	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
	assert(message != NULL);
	
	xpc_dictionary_set_uint64(message, "encription", 1);
	
	xpc_connection_send_message_with_reply(self.scriptServiceConnection, message,
										   dispatch_get_main_queue(), ^(xpc_object_t event)
	{
	   if (xpc_dictionary_get_value(event, "encription") != NULL)
	   {
		   bool encription = xpc_dictionary_get_bool(event, "encription");
		   self.bEncription = encription;
		   if (self.bEncription) {
			   m_bAutoPrefs = false;
		   }
		   
		   DBNSLog(@"Encription: %d", encription);
	   }
	});

	[self loadUserSettings];

	if (m_bUseIconOnMainMenu) {
		[self makeMenu];
	}
	
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
	[[NSOperationQueue mainQueue] cancelAllOperations];
	[self saveUserSettings];
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

- (IBAction)toggleStartup:(id)sender {
    bool enableStartup = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableStartup"];
    [loginController setStartAtLogin: enableStartup];
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
			//[self makeBlockLock];
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
	
	if (!self.bEncription) {
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
	
	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
    assert(message != NULL);
	
    xpc_dictionary_set_uint64(message, "locktype", LOCK_SCREEN);
	
    xpc_connection_send_message_with_reply(self.scriptServiceConnection, message,
                                           dispatch_get_main_queue(), ^(xpc_object_t event) {
											   
										   });
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
	
	if (!self.bEncription) {
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
			/*for(NSWindow *blocker in _blockObjects) {
				[blocker orderOut:self];
				DBNSLog(@"closing blocker");
			}*/
			
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
		
		if (success)
		{
			DBNSLog(@"Can't sync Prefs");
		}
		
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
			if (success)
			{
				DBNSLog(@"Can't start screensaver");
			}
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
	m_bNeedResumeiTunes = [[defaults objectForKey:kResumeiTunes] boolValue];
}

-(void) saveUserSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    [defaults setBool:m_bUseIconOnMainMenu forKey:kIconOnMainMenu];
	[defaults setInteger:m_iLockType forKey:kLockType];
	[defaults setBool:m_bPauseiTunes forKey:kPauseiTunes];
	[defaults setBool:m_bResumeiTunes forKey:kResumeiTunes];
	[defaults setBool:m_bAutoPrefs forKey:kAutoScreenSaverPrefs];
	
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

#pragma mark - GUI

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

@end
