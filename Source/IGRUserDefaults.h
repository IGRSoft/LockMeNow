//
//  IGRUserDefaults.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/19/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LockingType)
{
	LOCK_LOGIN_WINDOW = 0,
	LOCK_SCREEN,
	LOCK_BLOCK,
};

typedef NS_ENUM(NSUInteger, DeviceType)
{
	USB_ALL_DEVICES = 0,
	USB_IPHONE,
	USB_IPOD,
	USB_IPAD
};

typedef void (^IGRUserDefaultsBluetoothData)(NSData *bluetoothData);

@interface IGRUserDefaults : NSObject

@property (nonatomic, assign) BOOL bEnableStartup;
@property (nonatomic, assign) BOOL bUseIconOnMainMenu;
@property (nonatomic, assign) BOOL bPauseiTunes;
@property (nonatomic, assign) BOOL bUseCurrentScreenSaver;
@property (nonatomic, assign) BOOL bResumeiTunes;
@property (nonatomic, assign) BOOL bNeedResumeiTunes;
@property (nonatomic, assign) BOOL bAutoPrefs;
@property (nonatomic, assign) NSNumber *iLockType;
@property (nonatomic, assign) BOOL bMonitoringUSB;
@property (nonatomic, assign) NSNumber *iUSBDeviceType;
@property (nonatomic, assign) BOOL bMonitoringBluetooth;
@property (nonatomic, strong) id keyCombo;
@property (nonatomic, strong) NSData *bluetoothData;

- (void)loadUserSettings;
- (void)saveUserSettingsWithBluetoothData:(NSData *)bluetoothData;

- (LockingType)lockingType;
- (DeviceType)deviceType;


@end
