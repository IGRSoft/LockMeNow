//
//  IGRUserDefaults.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/19/15.
//
//

#import "IGRUserDefaults.h"

NSString *kEnableStartup                    = @"EnableStartup";
NSString *kGlobalHotKey                     = @"LockMeNowHotKey";
NSString *kIconOnMainMenu                   = @"IconOnMainMenu";
NSString *kLockType                         = @"LockType";
NSString *kUseCurrentScreenSaver            = @"UseCurrentScreenSaver";
NSString *kPauseiTunes                      = @"PauseiTunes";
NSString *kResumeiTunes                     = @"ResumeiTunes";
NSString *kBluetoothDevice                  = @"BluetoothDevice";
NSString *kBluetoothCheckInterval           = @"BluetoothCheckInterval";
NSString *kBluetoothMonitoring              = @"BluetoothMonitoring";
NSString *kUSBMonitoring                    = @"USBMonitoring";
NSString *kUSBDeviceType                    = @"USBDevice";
NSString *kMakePhotoOnIncorrectPasword      = @"MakePhotoOnIncorrectPasword";
NSString *kSendPhotoOnIncorrectPasword      = @"SendPhotoOnIncorrectPasword";
NSString *kIncorrectPaswordMail             = @"IncorrectPaswordMail";
NSString *kSendLocationOnIncorrectPasword   = @"SendLocationOnIncorrectPasword";
NSString *kPhotoQualityType                 = @"PhotoQualityType";
NSString *kControllMegSafe                  = @"ControllMegSafe";

@interface IGRUserDefaults ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation IGRUserDefaults

- (void)initialize
{
	// Create a dictionary
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	defaultValues[kEnableStartup] = @NO;
	defaultValues[kIconOnMainMenu] = @YES;
	defaultValues[kLockType] = @(LOCK_SCREEN);
	defaultValues[kUseCurrentScreenSaver] = @NO;
	defaultValues[kPauseiTunes] = @NO;
	defaultValues[kResumeiTunes] = @NO;
	
	defaultValues[kBluetoothCheckInterval] = @60;
	defaultValues[kBluetoothMonitoring] = @NO;
	defaultValues[kUSBMonitoring] = @NO;
	defaultValues[kUSBDeviceType] = @(USB_ALL_DEVICES);
    
    defaultValues[kMakePhotoOnIncorrectPasword] = @NO;
    defaultValues[kSendPhotoOnIncorrectPasword] = @NO;
	defaultValues[kControllMegSafe] = @NO;
    defaultValues[kIncorrectPaswordMail] = @"";
	defaultValues[kSendLocationOnIncorrectPasword] = @NO;
    defaultValues[kPhotoQualityType] = @(PHOTO_QUALITY_TYPE_GOOD);
    
	// Register the dictionary of defaults
	[self.defaults registerDefaults: defaultValues];
	//DBNSLog(@"registered defaults: %@", defaultValues);
}

- (instancetype)init
{
	if (self = [super init])
	{
		NSString *bundleIdentifier = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
		bundleIdentifier = [@"sandbox." stringByAppendingString:bundleIdentifier];
		
		_defaults = [[NSUserDefaults alloc] initWithSuiteName:bundleIdentifier];
		[self initialize];
		[self loadUserSettings];
	}
	
	return self;
}

- (void)loadUserSettings
{
	_bEnableStartup                     = [self.defaults boolForKey:kEnableStartup];
	_bUseIconOnMainMenu                 = [self.defaults boolForKey:kIconOnMainMenu];
	_iLockType                          = [self.defaults objectForKey:kLockType];
	_bUseCurrentScreenSaver             = [self.defaults boolForKey:kUseCurrentScreenSaver];
	_bPauseiTunes                       = [self.defaults boolForKey:kPauseiTunes];
	_bResumeiTunes                      = [self.defaults boolForKey:kResumeiTunes];
	_bNeedResumeiTunes                  = [self.defaults boolForKey:kResumeiTunes];
	_keyCombo                           = [self.defaults objectForKey:kGlobalHotKey];
    _bMakePhotoOnIncorrectPasword       = [self.defaults boolForKey:kMakePhotoOnIncorrectPasword];
    _bSendMailOnIncorrectPasword        = [self.defaults boolForKey:kSendPhotoOnIncorrectPasword];
    _sIncorrectPaswordMail              = [self.defaults objectForKey:kIncorrectPaswordMail];
    _bSendLocationOnIncorrectPasword    = [self.defaults boolForKey:kSendLocationOnIncorrectPasword];
    _iPhotoQualityType                  = [self.defaults objectForKey:kPhotoQualityType];
	_bControllMagSafe					= [self.defaults boolForKey:kControllMegSafe];
    
	NSData *deviceAsData                = [self.defaults objectForKey:kBluetoothDevice];
	if( [deviceAsData length] > 0 )
	{
		_bluetoothData = deviceAsData;
	}
	
	// Monitoring enabled
	_bMonitoringBluetooth               = [self.defaults boolForKey:kBluetoothMonitoring];
	_bMonitoringUSB                     = [self.defaults boolForKey:kUSBMonitoring];
	_iUSBDeviceType                     = [self.defaults objectForKey:kUSBDeviceType];
}

- (void)saveUserSettingsWithBluetoothData:(NSData *)bluetoothData
{
	[self.defaults setBool:_bUseIconOnMainMenu forKey:kIconOnMainMenu];
	[self.defaults setObject:_iLockType forKey:kLockType];
	[self.defaults setBool:_bUseCurrentScreenSaver forKey:kUseCurrentScreenSaver];
	[self.defaults setBool:_bPauseiTunes forKey:kPauseiTunes];
	[self.defaults setBool:_bResumeiTunes forKey:kResumeiTunes];
	[self.defaults setBool:_bEnableStartup forKey:kEnableStartup];
    [self.defaults setBool:_bMakePhotoOnIncorrectPasword forKey:kMakePhotoOnIncorrectPasword];
    [self.defaults setBool:_bSendMailOnIncorrectPasword forKey:kSendPhotoOnIncorrectPasword];
    [self.defaults setObject:_sIncorrectPaswordMail forKey:kIncorrectPaswordMail];
    [self.defaults setBool:_bSendLocationOnIncorrectPasword forKey:kSendLocationOnIncorrectPasword];
    [self.defaults setObject:_iPhotoQualityType forKey:kPhotoQualityType];
	[self.defaults setBool:_bControllMagSafe forKey:kControllMegSafe];
    
	// Monitoring enabled
	[self.defaults setBool:_bMonitoringBluetooth forKey:kBluetoothMonitoring];
	
	// Device
	if( bluetoothData )
	{
		[self.defaults setObject:bluetoothData forKey:kBluetoothDevice];
	}
	
	if( _keyCombo )
	{
		[self.defaults setObject:_keyCombo forKey:kGlobalHotKey];
	}
	
	[self.defaults setBool:_bMonitoringUSB forKey:kUSBMonitoring];
	[self.defaults setObject:_iUSBDeviceType forKey:kUSBDeviceType];
	
	[self.defaults synchronize];
}

- (LockingType)lockingType
{
	return [_iLockType integerValue];
}

- (DeviceType)deviceType
{
	return [_iUSBDeviceType integerValue];
}

- (PhotoQualityType)photoQualityType
{
    return [_iPhotoQualityType integerValue];
}

@end
