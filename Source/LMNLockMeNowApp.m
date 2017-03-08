//
//  LMNLockMeNowApp.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import "LMNLockMeNowApp.h"

#import "LMNLockManager.h"
#import "LMNJustLock.h"
#import "LMNLoginWindowsLock.h"

#import "LMNListenerManager.h"
#import "LMNKeyListener.h"
#import "LMNUSBListener.h"
#import "LMNBluetoothListener.h"

#import "ImageSnap.h"

#import <CoreLocation/CoreLocation.h>

#import "XPCScriptingProtocol.h"
#import "XPCScriptingBridgeProtocol.h"

#import <ServiceManagement/ServiceManagement.h>
#import <xpc/xpc.h>

#include <pwd.h>
#include <grp.h>



@interface LMNLockMeNowApp() <LMNLockManagerDelegate, LMNListenerManagerDelegate,
                                    NSUserNotificationCenterDelegate, CLLocationManagerDelegate>

@property (nonatomic) NSXPCConnection *scriptServiceConnection;
@property (nonatomic) NSXPCConnection *scriptingBridgeServiceConnection;

@property (nonatomic) IGRUserDefaults *userSettings;

@property (nonatomic) LMNLockManager *lockManager;
@property (nonatomic) LMNUSBListener *usbListener;
@property (nonatomic) LMNBluetoothListener *bluetoothListener;

@property (nonatomic) BOOL isASLPatched;

@property (nonatomic) NSString *thiefPhotoPath;
@property (nonatomic) CLLocation *location;

@property (nonatomic) CLLocationManager *locationManager;

- (BOOL)autorizateForService:(NSString *)aService
                       error:(NSError * __autoreleasing *)error;
- (IBAction)selectPhotoQuality:(NSComboBox *)sender;

@end

@implementation LMNLockMeNowApp

- (instancetype)init
{
    if (self = [super init])
    {
        _userSettings = [[IGRUserDefaults alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    self.locationManager.delegate = nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)theNotification
{
    NSString *filePath = [theNotification userInfo][@"filePath"];
    if (filePath)
    {
        DBNSLog(@"%@", theNotification);
        [[NSWorkspace sharedWorkspace] selectFile:filePath inFileViewerRootedAtPath:@""];
    }
    
    // Prep XPC services.
    [self registeryXPC];
    
    //Registery Listeners
    self.keyListener.userSettings = self.userSettings;
    self.keyListener.delegate = self;
    
    self.usbListener = [[LMNUSBListener alloc] initWithSettings:self.userSettings];
    self.usbListener.delegate = self;
    
    self.bluetoothListener = [[LMNBluetoothListener alloc] initWithSettings:self.userSettings];
    self.bluetoothListener.delegate = self;
    
    __weak typeof(self) weakSelf = self;
    self.bluetoothListener.bluetoothStatusChangedBlock = ^(BluetoothStatus bluetoothStatus) {
        
        [weakSelf updateBluetoothStatus:bluetoothStatus];
    };
    
    //GUI
    [self updateBluetoothStatus:OutOfRange];
    
    if (self.userSettings.bUseIconOnMainMenu)
    {
        [self makeMenu];
    }
    
    self.isASLPatched = system("odutil set log warning") == 0;
    if (weakSelf.isASLPatched && weakSelf.userSettings.bSendLocationOnIncorrectPasword)
    {
        weakSelf.locationManager = [[CLLocationManager alloc] init];
        weakSelf.locationManager.delegate = weakSelf;
    }

    [self setTakePhotoOnIncorrectPassword:nil];
    [self.thiefPhotoQuality selectItemAtIndex:self.userSettings.iPhotoQualityType.integerValue];
    
    //Setup lock Type
    [self setupLock];
}

- (void)applicationDidChangeOcclusionState:(NSNotification *)notification
{
    NSString *state = IGRNotificationScreenLocked;
    if ([NSApp occlusionState] & NSApplicationOcclusionStateVisible)
    {
        state = IGRNotificationScreenUnLocked;
    }
    
    DBNSLog(@"Post Notification: %@", state);
    
    NSUInteger options = NSNotificationDeliverImmediately | NSNotificationPostToAllSessions;
    NSDistributedNotificationCenter* distCenter = [NSDistributedNotificationCenter defaultCenter];
    
    [distCenter postNotificationName:state
                              object:nil
                            userInfo:nil
                             options:options];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    static BOOL doNothingAtStart = YES;
    if (doNothingAtStart)
    {
        doNothingAtStart = NO;
    }
    else
    {
        [self.window makeKeyAndOrderFront:self];
    }
}

- (void)applicationWillTerminate:(NSNotification *)theNotification
{
    [self.keyListener stopListen];
    [self.usbListener stopListen];
    [self.bluetoothListener stopListen];
    
    [_scriptingBridgeServiceConnection invalidate];
    [_scriptServiceConnection invalidate];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (_lockManager.allowTerminate)
    {
        return NSTerminateNow;
    }
    
    return NSTerminateCancel;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //About
    NSString *text = [self.aboutText stringValue];
    
    [self.aboutText setAllowsEditingTextAttributes: YES];
    [self.aboutText setSelectable: YES];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:text];
    [attrString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:13] range:[text rangeOfString:text]];
    
    NSMutableParagraphStyle *truncateStyle = [[NSMutableParagraphStyle alloc] init];
    [truncateStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    
    [attrString beginEditing];
    
    NSColor *color = [NSColor colorWithCalibratedRed:0.058 green:0.385 blue:0.784 alpha:1.000];
    NSRange range = [text rangeOfString:@"Vitalii Parovishnyk"];
    NSURL *url = [NSURL URLWithString:@"https://github.com/IGRSoft/LockMeNow"];
    
    if (range.location != NSNotFound)
    {
        NSDictionary *dict = @{	NSLinkAttributeName: url,
                                NSForegroundColorAttributeName:color,
                                NSCursorAttributeName:[NSCursor pointingHandCursor],
                                NSParagraphStyleAttributeName:truncateStyle
                                };
        [attrString addAttributes:dict range:range];
    }
    
    range = [text rangeOfString:@"@iKorich"];
    url = [NSURL URLWithString:TWITTER_SITE];
    
    if (range.location != NSNotFound)
    {
        NSDictionary *dict = @{	NSLinkAttributeName: url,
                                NSForegroundColorAttributeName:color,
                                NSCursorAttributeName:[NSCursor pointingHandCursor],
                                NSParagraphStyleAttributeName:truncateStyle
                                };
        [attrString addAttributes:dict range:range];
    }
    
    [attrString endEditing];
    
    [self.aboutText setAttributedStringValue:attrString];
}

#pragma mark - Actions

- (void)setupLock
{
    Class lockClass = NULL;
    switch ([self.userSettings lockingType])
    {
        case LOCK_SCREEN:
            lockClass = [LMNJustLock class];
            break;
        case LOCK_BLOCK:
            //[self makeBlockLock];
            break;
        case LOCK_LOGIN_WINDOW:
        default:
            lockClass = [LMNLoginWindowsLock class];
            break;
    }
    
    self.lockManager = [[lockClass alloc] initWithConnection:self.scriptServiceConnection
                                                    settings:self.userSettings];
    self.lockManager.delegate = self;
}

- (IBAction)goToURL:(id)sender
{
    NSURL *url = [NSURL URLWithString:APP_SITE];
    
    if ([[sender title] isEqualToString:@"Site"])
    {
        url = [NSURL URLWithString:APP_SITE ];
    }
    else if ([[sender title] isEqualToString:@"Twitter"])
    {
        url = [NSURL URLWithString:TWITTER_SITE ];
    }
    else if ([[sender title] isEqualToString:@"Donate"])
    {
        url = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ENPVXEYJUQU9G" ];
    }
    else if ([sender tag] == 1)
    {
        url = [NSURL URLWithString:@"http://russianapple.ru" ];
    }
    
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openPrefs:(id)sender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront: self];
    [self.window makeMainWindow];
}

#pragma mark - Lock

- (IBAction)doLock:(id)sender
{
#if 0
    [self detectedEnterPassword];
#else
    self.userSettings.bNeedResumeiTunes = NO;
    self.thiefPhotoPath = nil;
    
    [self pauseResumeMusic];
    
    [self.lockManager lock];
    
    if (self.userSettings.bSendLocationOnIncorrectPasword)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [_locationManager startUpdatingLocation];
        _locationManager.delegate = self;
    }
#endif
}

- (IBAction)doUnLock:(id)sender
{
    [self.lockManager unlockByLockManager:YES];
}

- (IBAction)applyASLPatch:(id)sender
{
    self.patchStatus.stringValue = @"Applying patch...";
    
    NSButton *button = sender;
    button.enabled = NO;
    [self.patchASLProgress startAnimation:self];
    self.patchASLProgress.hidden = NO;
    
    self.isASLPatched = system("odutil set log warning") == 0;
    
    [self.patchASLProgress stopAnimation:self];
    self.patchASLProgress.hidden = self.isASLPatched;
    button.enabled = YES;
}

#pragma mark - Preferences

- (IBAction)setMenuIcon:(id)sender
{
    [self makeMenu];
    
    [self updateUserSettings:sender];
}

- (IBAction)setMonitoringBluetooth:(id)sender
{
    if (self.userSettings.bMonitoringBluetooth)
    {
        [self.bluetoothListener startListen];
    }
    else
    {
        [self.bluetoothListener stopListen];
    }
    
    [self updateUserSettings:sender];
}

- (IBAction)setMonitoringUSBDevice:(id)sender
{
    if (self.userSettings.bMonitoringUSB)
    {
        [self.usbListener startListen];
    }
    else
    {
        [self.usbListener stopListen];
    }
    
    [self updateUserSettings:sender];
}

- (IBAction)toggleStartup:(id)sender
{
    if ( !SMLoginItemSetEnabled((__bridge CFStringRef)@"com.igrsoft.LaunchHelper", self.userSettings.bEnableStartup) )
    {
        DBNSLog(@"Can't start com.igrsoft.LaunchHelper");
    }
    
    [self updateUserSettings:sender];
}

- (IBAction)setLockType:(id)sender
{
    [self setupLock];
    
    [self updateUserSettings:sender];
}

- (IBAction)setTakePhotoOnIncorrectPassword:(NSButton *)sender
{
    if (sender.state == NSOnState) {
        uid_t current_user_id = getuid();
        
        struct passwd *pwentry = getpwuid(current_user_id);
        struct group *admin_group = getgrnam("admin");
        
        BOOL isAdmin = NO;
        while(*admin_group->gr_mem != NULL) {
            if (strcmp(pwentry->pw_name, *admin_group->gr_mem) == 0) {
                isAdmin = YES;
                break;
            }
            admin_group->gr_mem++;
        }
        
        if (!isAdmin)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Security Check";
            alert.informativeText = @"To enable this option, you must be in Administration group!";
            
            [alert runModal];
            
            self.userSettings.bMakePhotoOnIncorrectPasword = NO;
            
            return;
        }
    }
    
    self.sendMailCheckbox.title = self.userSettings.bMakePhotoOnIncorrectPasword ?
    @"Send photo and warning on email:" :
    @"Send warning on email:";
    
    if (sender)
    {
        [self updateUserSettings:sender];
    }
}

- (IBAction)setSendLocation:(id)sender
{
    self.locationManager = [[CLLocationManager alloc] init];
    
    if (self.userSettings.bSendLocationOnIncorrectPasword)
    {
        //need check acces to Location Service
        self.locationManager.delegate = self;
    }
    
    [self updateUserSettings:sender];
}

- (IBAction)updateUserSettings:(id)sender
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [weakSelf.userSettings saveUserSettingsWithBluetoothData:nil];
    });
}

#pragma mark - Actions

- (void)pauseResumeMusic
{
    if (self.userSettings.bPauseiTunes)
    {
        __weak typeof(self) weakSelf = self;
        if (!self.userSettings.bNeedResumeiTunes)
        {
            [[_scriptingBridgeServiceConnection remoteObjectProxy] isMusicPlaingWithReply:^(BOOL isMusicPlaing) {
                if (isMusicPlaing)
                {
                    [[weakSelf.scriptingBridgeServiceConnection remoteObjectProxy] playPauseMusic];
                    weakSelf.userSettings.bNeedResumeiTunes = YES;
                }
            }];
        }
        else if (self.userSettings.bNeedResumeiTunes && self.userSettings.bResumeiTunes)
        {
            [[_scriptingBridgeServiceConnection remoteObjectProxy] isMusicPausedWithReply:^(BOOL isMusicPaused) {
                if (isMusicPaused)
                {
                    [[weakSelf.scriptingBridgeServiceConnection remoteObjectProxy] playPauseMusic];
                    weakSelf.userSettings.bNeedResumeiTunes = NO;
                }
            }];
        }
    }
}

- (NSString *)takePhoto
{
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
    
    dateString = [formatter stringFromDate:[NSDate date]];
    dateString = [dateString stringByAppendingPathExtension:@"png"];
    
    NSString *picturePath = [NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES) firstObject];
    picturePath = [picturePath stringByAppendingPathComponent:@"LockMeNow"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    
    if ([fm fileExistsAtPath:picturePath isDirectory:&isDir] && isDir)
    {
    }
    else
    {
        [fm createDirectoryAtPath:picturePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    picturePath = [picturePath stringByAppendingPathComponent:dateString];
    
    AVCaptureDevice *defaultVideoDevice = [ImageSnap defaultVideoDevice];
    BOOL result = [ImageSnap saveSnapshotFrom:defaultVideoDevice
                                       toFile:picturePath
                                   withWarmup:@(self.userSettings.iPhotoQualityType.integerValue)];
    
    return result ? picturePath : nil;
}

- (BOOL)autorizateForService:(NSString *)aService
                       error:(NSError * __autoreleasing *)error
{
    BOOL result = NO;
    
    AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights	= { 1, &authItem };
    AuthorizationFlags flags		=	kAuthorizationFlagDefaults				|
                                        kAuthorizationFlagInteractionAllowed	|
                                        kAuthorizationFlagPreAuthorize			|
                                        kAuthorizationFlagExtendRights;
    
    AuthorizationRef authRef = NULL;
    
    /* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status == errAuthorizationSuccess)
    {
        /* This does all the work of verifying the helper tool against the application
         * and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        CFErrorRef cfError = nil;
        result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)aService, authRef, &cfError);
        
        if (error != nil && !result && cfError)
        {
            *error = CFBridgingRelease(cfError);
        }
    }
    
    return result;
}

- (IBAction)selectPhotoQuality:(NSComboBox *)sender
{
    self.userSettings.iPhotoQualityType = @(sender.indexOfSelectedItem);
    
    [self updateUserSettings:sender];
}

#pragma mark - Bluetooth

- (IBAction)changeDevice:(id)sender
{
    [self.bluetoothListener changeDevice];
}

#pragma mark - GUI

- (void)updateBluetoothStatus:(BluetoothStatus)bluetoothStatus
{
    NSImage *img = [NSImage imageNamed:(bluetoothStatus == InRange) ? @"on" : @"off"];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [weakSelf.bluetoothStatus setImage:img];
        [weakSelf.bluetoothStatus setNeedsDisplay:YES];
    });
}

- (void)makeMenu
{
    if (self.userSettings.bUseIconOnMainMenu && self.statusItem == nil)
    {
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        
        NSStatusBarButton *button = statusItem.button;
        
        button.target = self;
        button.action = @selector(toggleDropDownMenu:);
        
        [button sendActionOn:(NSLeftMouseUpMask | NSRightMouseUpMask)];
        
        self.statusItem = statusItem;
        
        button.image = [NSImage imageNamed:@"lock"];
        button.appearsDisabled = NO;
        button.toolTip = NSLocalizedString(@"Click to show menu", nil);
        
    }
    else if (!self.userSettings.bUseIconOnMainMenu && self.statusItem != nil)
    {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
        self.statusItem = nil;
    }
}

- (void)toggleDropDownMenu:(id)sender
{
    [self.statusItem popUpStatusItemMenu:self.statusMenu];
}

#pragma mark - XPC

- (void)registeryXPC
{
    // XPC Script
    _scriptServiceConnection = [[NSXPCConnection alloc] initWithServiceName:XPC_SCRIPTING];
    _scriptServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCScriptingProtocol)];
    [_scriptServiceConnection resume];
    
    _scriptingBridgeServiceConnection = [[NSXPCConnection alloc] initWithServiceName:XPC_SCRIPTING_BRIDGE];
    _scriptingBridgeServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCScriptingBridgeProtocol)];
    [_scriptingBridgeServiceConnection resume];
}

- (xpc_connection_t)connectionForServiceNamed:(const char *)serviceName
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
    
    xpc_connection_set_event_handler(serviceConnection, ^(xpc_object_t event) {
        
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
    
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    
    if (self.thiefPhotoPath)
    {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:@"Security Warning!"];
        [notification setSubtitle:@"Someone has entered an incorrect password!"];
        [notification setInformativeText:@"You can check his/her photo"];
        
        
        [notification setUserInfo:@{@"filePath": self.thiefPhotoPath}];
        
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center setDelegate:self];
        [center scheduleNotification:notification];
    }
    
    [self.usbListener reset];
    [self.bluetoothListener reset];
}

- (void)detectedUnplygMagSafeAction
{
    [self detectedWrongLoginAction:UNPLUG_MAGSAFE_ACTION];
}

- (void)detectedEnterPassword
{
    [self detectedWrongLoginAction:WRONG_PASSWORD_ACTION];
}

- (void)detectedWrongLoginAction:(WrongUserActionType)type
{
    [self updateLocationManager];

    if (self.userSettings.bMakePhotoOnIncorrectPasword)
    {
        self.thiefPhotoPath = [self takePhoto];
    }

    if (self.userSettings.bSendMailOnIncorrectPasword && self.userSettings.sIncorrectPaswordMail.length)
    {
        [[_scriptingBridgeServiceConnection remoteObjectProxy] setupMailAddres:self.userSettings.sIncorrectPaswordMail
                                                                     userPhoto:self.thiefPhotoPath
                                                                          type:type];
    }
    else
    {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void (^SendLocation)(void) = ^{
        
        if (self.location)
        {
            NSString *theLocation = [NSString stringWithFormat:@"https://maps.google.com/maps?q=%f,%f&num=1&vpsrc=0&ie=UTF8&t=m",
                                     weakSelf.location.coordinate.latitude,
                                     weakSelf.location.coordinate.longitude];
            
            [[weakSelf.scriptingBridgeServiceConnection remoteObjectProxy] sendDefaultMessageAddLocation:theLocation];
        }
        else
        {
            [[weakSelf.scriptingBridgeServiceConnection remoteObjectProxy] sendDefaultMessageAddLocation:nil];
        }
    };
    
    if (self.userSettings.bSendLocationOnIncorrectPasword)
    {
        //wait one sec to detect better position
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            SendLocation();
        });
    }
    else
    {
        SendLocation();
    }
}

- (void)updateLocationManager
{
    if (self.userSettings.bSendLocationOnIncorrectPasword)
    {
        [_locationManager stopUpdatingLocation];
        [_locationManager startUpdatingLocation];
    }
}

#pragma mark - ListenerManagerDelegate

- (void)makeLockAction:(id)sender
{
    [self doLock:sender];
}

- (void)makeUnlockAction:(id)sender
{
    [self doUnLock:sender];
}

#pragma mark - UserNotificationCenter

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSString *filePath = [notification userInfo][@"filePath"];
    if (filePath)
    {
        [[NSWorkspace sharedWorkspace] selectFile:filePath inFileViewerRootedAtPath:@""];
    }
    [center removeDeliveredNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)userNotification;
{
    return YES;
}
#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            [_locationManager startUpdatingLocation];
        case kCLAuthorizationStatusAuthorized:
            [_locationManager stopUpdatingLocation];
            
            break;
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
        {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"You chould enable Location Service";
            alert.informativeText = @"Please, open Privacy tab\nand enable Location Service\nfor Lock Me Naw application\nin System Preferences -> Security & Privacy.";
            
            [alert runModal];
            
            NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"];
            [[NSWorkspace sharedWorkspace] openURL:url];
        }
            break;
            
        default:
            break;
    }
    
    self.userSettings.bSendLocationOnIncorrectPasword = (status == kCLAuthorizationStatusAuthorized);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (self.lockManager.isLocked)
    {
        self.location = [locations lastObject];
        
        DBNSLog(@"Location: %@", self.location);
    }
}

@end
