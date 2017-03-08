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
    USB_NONE = -1,
	USB_ALL_DEVICES = 0,
	USB_IPHONE,
	USB_IPOD,
	USB_IPAD
};

typedef NS_ENUM(NSUInteger, PhotoQualityType)
{
    PHOTO_QUALITY_TYPE_NORMAL = 0,
    PHOTO_QUALITY_TYPE_GOOD,
    PHOTO_QUALITY_TYPE_BEST,
};

typedef NS_ENUM(NSUInteger, WrongUserActionType)
{
    WRONG_PASSWORD_ACTION = 0,
    UNPLUG_MAGSAFE_ACTION,
};

typedef void (^IGRUserDefaultsBluetoothData)(NSData *bluetoothData);

@interface IGRUserDefaults : NSObject

@property (nonatomic, assign) BOOL bEnableStartup;
@property (nonatomic, assign) BOOL bUseIconOnMainMenu;
@property (nonatomic, assign) BOOL bPauseiTunes;
@property (nonatomic, assign) BOOL bUseCurrentScreenSaver;
@property (nonatomic, assign) BOOL bResumeiTunes;
@property (nonatomic, assign) BOOL bNeedResumeiTunes;
@property (nonatomic, assign) NSNumber *iLockType;
@property (nonatomic, assign) BOOL bMonitoringUSB;
@property (nonatomic, assign) NSNumber *iUSBDeviceType;
@property (nonatomic, assign) BOOL bMonitoringBluetooth;
@property (nonatomic, strong) id keyCombo;
@property (nonatomic, copy  ) NSData *bluetoothData;
@property (nonatomic, assign) NSNumber *iPhotoQualityType;
@property (nonatomic, assign) BOOL bControllMagSafe;

@property (nonatomic, assign) BOOL bMakePhotoOnIncorrectPasword;
@property (nonatomic, assign) BOOL bSendMailOnIncorrectPasword;
@property (nonatomic, copy  ) NSString *sIncorrectPaswordMail;
@property (nonatomic, assign) BOOL bSendLocationOnIncorrectPasword;

- (void)loadUserSettings;
- (void)saveUserSettingsWithBluetoothData:(NSData *)bluetoothData;

@property (nonatomic, readonly) LockingType lockingType;
@property (nonatomic, readonly) DeviceType deviceType;
@property (nonatomic, readonly) PhotoQualityType photoQualityType;

@end
