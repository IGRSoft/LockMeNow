//
//  LockMeNowAppDelegate.m
//  Lock Me Now
//
//  Created by Vitaly Parovishnik on 20.07.11.
//  Copyright 2010 IGR Software. All rights reserved.
//

#import "LockMeNowAppDelegate.h"

#import "LockManager.h"
#import "JustLock.h"
#import "LoginWindowsLock.h"

#import "ListenerManager.h"
#import "KeyListener.h"
#import "USBListener.h"
#import "BluetoothListener.h"

#import "iTunesHelper.h"
#import "MailHelper.h"
#import "ImageSnap.h"

#import "ASLHelper.h"
#import <CoreLocation/CoreLocation.h>

#import <ServiceManagement/ServiceManagement.h>
#import <xpc/xpc.h>

@interface LockMeNowAppDelegate() <LockManagerDelegate, ListenerManagerDelegate, NSUserNotificationCenterDelegate, CLLocationManagerDelegate>
{
    MailHelper *mailHelper;
}

@property (nonatomic) xpc_connection_t scriptServiceConnection;
@property (nonatomic) IGRUserDefaults *userSettings;

@property (nonatomic) LockManager *lockManager;
@property (nonatomic) USBListener *usbListener;
@property (nonatomic) BluetoothListener *bluetoothListener;

@property (nonatomic) BOOL isASLPatched;

@property (nonatomic) CLLocationManager *locationManager;


@end

@implementation LockMeNowAppDelegate

- (instancetype) init
{
    if (self= [super init])
    {
        self.userSettings = [[IGRUserDefaults alloc] init];
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)theNotification
{
    NSString *filePath = [theNotification userInfo][@"filePath"];
    if (filePath)
    {
        DBNSLog(@"%@", theNotification);
        [[NSWorkspace sharedWorkspace] selectFile: filePath inFileViewerRootedAtPath: nil];
    }
    
    // Prep XPC services.
    [self registeryXPC];
    
    //Registery Listeners
    self.keyListener.userSettings = self.userSettings;
    self.keyListener.delegate = self;
    
    self.usbListener = [[USBListener alloc] initWithSettings:self.userSettings];
    self.usbListener.delegate = self;
    
    self.bluetoothListener = [[BluetoothListener alloc] initWithSettings:self.userSettings];
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
    
    self.isASLPatched = [ASLHelper isASLPatched];
    [self setTakePhotoOnIncorrectPassword:nil];
    
    //need check acces to Location Service
    if (self.isASLPatched && self.userSettings.bSendLocationOnIncorrectPasword)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    //Setup lock Type
    [self setupLock];
}

- (void)setupLock
{
    Class lockClass = NULL;
    switch ([self.userSettings lockingType])
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
    
    self.lockManager = [[lockClass alloc] initWithConnection:self.scriptServiceConnection settings:self.userSettings];
    self.lockManager.delegate = self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:self.donateButton.title];
    NSUInteger len = [attrTitle length];
    NSRange range = NSMakeRange(0, len);
    
    [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:range];
    [attrTitle addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Helvetica Bold Oblique" size:12] range:range];
    
    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    [paragrahStyle setAlignment:kCTTextAlignmentCenter];
    
    [attrTitle addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:range];
    
    [attrTitle fixAttributesInRange:range];
    [self.donateButton setAttributedTitle:attrTitle];
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
    [self.keyListener stopListen];
    [self.usbListener stopListen];
    [self.bluetoothListener stopListen];
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
    NSURL *url = [NSURL URLWithString:APP_SITE];
    
    if ([[sender title] isEqualToString:@"Site"])
    {
        url = [NSURL URLWithString:APP_SITE ];
    }
    else if ([[sender title] isEqualToString:@"Twitter"])
    {
        url = [NSURL URLWithString:@"http://twitter.com/#!/iKorich" ];
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
    [self.window center];
}

#pragma mark - Lock

- (IBAction)doLock:(id)sender
{
    self.userSettings.bNeedResumeiTunes = NO;
    [self pauseResumeMusic];
    
    [self.lockManager lock];
}

- (IBAction)doUnLock:(id)sender
{
    //[self removeSecurityLock];
}

- (IBAction)applyASLPatch:(id)sender
{
    [self.patchASLProgress startAnimation:self];
    
    self.isASLPatched = [ASLHelper patchASL];
    
    [self.patchASLProgress stopAnimation:self];
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

- (IBAction)setTakePhotoOnIncorrectPassword:(id)sender
{
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
        _locationManager.delegate = self;
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
        if (!self.userSettings.bNeedResumeiTunes)
        {
            if ([iTunesHelper isItunesRuning] && [iTunesHelper isMusicPlaing])
            {
                [iTunesHelper playpause];
                self.userSettings.bNeedResumeiTunes = YES;
            }
        }
        else if (self.userSettings.bNeedResumeiTunes && self.userSettings.bResumeiTunes)
        {
            if ([iTunesHelper isItunesRuning] && [iTunesHelper isMusicPaused])
            {
                [iTunesHelper playpause];
                self.userSettings.bNeedResumeiTunes = NO;
            }
        }
    }
}

- (NSString *)takePhoto
{
    NSDateFormatter *formatter;
    NSString        *dateString;
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy_HH-mm-ss"];
    
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
    
    BOOL result = [ImageSnap saveSnapshotFrom:[ImageSnap defaultVideoDevice] toFile:picturePath];
    
    return result ? picturePath : nil;
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

- (void) makeMenu
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
    self.scriptServiceConnection = [self connectionForServiceNamed:"com.igrsoft.lockmenow.script-service"
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
                                                   weakSelf.userSettings.bEncription = encription;
                                                   if (weakSelf.userSettings.bEncription)
                                                   {
                                                       weakSelf.userSettings.bAutoPrefs = NO;
                                                   }
                                                   
                                                   DBNSLog(@"Encription: %d", encription);
                                               }
                                           });
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
}

- (void)detectedWrongPassword
{
    NSString *photoPath = nil;
    
    if (self.userSettings.bMakePhotoOnIncorrectPasword)
    {
        photoPath = [self takePhoto];
    }
    
    if (self.userSettings.bSendMailOnIncorrectPasword && self.userSettings.sIncorrectPaswordMail.length)
    {
        self->mailHelper = [[MailHelper alloc] initWithMailAddres:self.userSettings.sIncorrectPaswordMail
                                                        userPhoto:photoPath];
        
        [self->mailHelper sendDefaultMessageAddLocation:self.userSettings.bSendLocationOnIncorrectPasword];
    }
    
    if (NSClassFromString(@"NSUserNotificationCenter"))
    {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:@"Security Warning!"];
        [notification setSubtitle:@"Someone has entered an incorrect password!"];
        [notification setInformativeText:@"You can check his/her photo"];
        
        if (photoPath)
        {
            [notification setUserInfo:@{@"filePath": photoPath}];
        }
        
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center setDelegate:self];
        [center scheduleNotification:notification];
    }
}

#pragma mark - ListenerManagerDelegate

- (void)makeAction:(id)sender
{
    [self doLock:sender];
}

#pragma mark - UserNotificationCenter

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    NSString *filePath = [notification userInfo][@"filePath"];
    if (filePath)
    {
        [[NSWorkspace sharedWorkspace] selectFile: filePath inFileViewerRootedAtPath: nil];
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
            NSAlert *alert = [NSAlert alertWithMessageText:@"You chould enable Location Service"
                                             defaultButton:nil
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Please, open Privacy tab and enable Location Service for Lock Me Naw application in System Preferences -> Security & Privacy."];
            
            [alert runModal];
            
            [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/Security.prefPane"];
        }
            break;
            
        default:
            break;
    }
    
    self.userSettings.bSendLocationOnIncorrectPasword = (status == kCLAuthorizationStatusAuthorized);
}

@end
