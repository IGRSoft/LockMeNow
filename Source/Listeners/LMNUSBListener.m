//
//  LMNUSBListener.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import "LMNUSBListener.h"

#import <IOKit/usb/IOUSBLib.h>
#import <mach/mach_port.h>
#import "PTUSBHub.h"

@interface LMNUSBListener ()

@property (nonatomic) NSInteger     usbDeviceID;
@property (nonatomic) DeviceType    currentUSBDeviceType;

@property (nonatomic, copy) NSString      *usbDeviceName;
@property (nonatomic, copy) NSString      *usbDeviceSerial;

@end

@implementation LMNUSBListener

- (instancetype)initWithSettings:(IGRUserDefaults *)aSettings
{
    if (self = [super initWithSettings:aSettings])
    {
        _currentUSBDeviceType = USB_NONE;
        
        if (self.userSettings.bMonitoringUSB)
        {
            [self startListen];
        }
    }
    
    return self;
}

static APPLE_MOBILE_DEVICE APPLE_MOBILE_DEVICES[NUM_APPLE_MOBILE_DEVICES] =
{
    { "iPhone",					0x1290 },
    { "iPhone 3G",				0x1292 },
    { "iPhone 3G[s]",			0x1294 },
    { "iPhone 4(GSM)",			0x1297 },
    { "iPhone 4(CDMA)",			0x129c },
    { "iPhone 4(R2)",			0x129c },
    { "iPhone 4S",				0x12a0 },
    { "iPhone 5 and Newer",     0x12a8 },
    
    { "iPod touch 1G",			0x1291 },
    { "iPod touch 2G",			0x1293 },
    { "iPod touch 3G",			0x1299 },
    { "iPod touch 4G",			0x129e },
    { "iPod touch 5G and Newer",0x12aa },
    
    { "iPad",					0x129a },
    { "iPad 2(WiFi)",			0x129f },
    { "iPad 2(GSM)",			0x12a2 },
    { "iPad 2(CDMA)",			0x12a3 },
    { "iPad 3(R2)",				0x12a9 },
    { "iPad 3(WiFi)",			0x12a4 },
    { "iPad 3(CDMA)",			0x12a5 },
    { "iPad 3(4G)",				0x12a6 },
    { "iPad 4 and Newer",       0x12ab },
};

- (void)startListen
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

- (void)stopListen
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc removeObserver:self
                  name:PTUSBDeviceDidAttachNotification
                object:PTUSBHub.sharedHub];
    
    [nc removeObserver:self
                  name:PTUSBDeviceDidDetachNotification
                object:PTUSBHub.sharedHub];
}

- (void)reset
{
    _currentUSBDeviceType = USB_NONE;
    _usbDeviceSerial = nil;
    
    if (self.userSettings.bMonitoringUSB)
    {
        [self stopListen];
        [self startListen];
    }
}

- (void)listeningDetachUSBDevice:(NSNotification *)note
{
    NSInteger _deviceID = [(note.userInfo)[@"DeviceID"] intValue];
    if (_usbDeviceID == _deviceID)
    {
        DBNSLog(@"%@ is disconnected by USB", _usbDeviceName);
        DeviceType deviceType = [self.userSettings deviceType];
        
        if (deviceType == _currentUSBDeviceType || deviceType == USB_ALL_DEVICES)
        {
            _usbDeviceID = 0;
            _usbDeviceName = nil;
            
            [self makeLockAction:self];
        }
    }
}

- (void)listeningAttachUSBDevice:(NSNotification *)note
{
    _usbDeviceID = 0;
    _currentUSBDeviceType = USB_NONE;
    
    uint16_t productID = [(note.userInfo)[@"Properties"][@"ProductID"] unsignedShortValue];
    NSString *usbDeviceSerial = (note.userInfo)[@"Properties"][@"SerialNumber"];
    
    if ([usbDeviceSerial isEqualToString:self.usbDeviceSerial]) {
        [self makeUnlockAction:self];
        self.usbDeviceSerial = nil;
    }
    
    if (!self.usbDeviceSerial.length)
    {
        for (NSInteger i = NUM_IPHONE_POS; i < NUM_APPLE_MOBILE_DEVICES; ++i)
        {
            APPLE_MOBILE_DEVICE iOSDevice = APPLE_MOBILE_DEVICES[i];
            if (productID == iOSDevice.productID)
            {
                DBNSLog(@"%s is connected by USB", iOSDevice.name);
                _usbDeviceID = [(note.userInfo)[@"DeviceID"] intValue];
                _usbDeviceName = [[NSString alloc] initWithCString:iOSDevice.name encoding:NSUTF8StringEncoding];
                _usbDeviceSerial = usbDeviceSerial;
                
                if (i < NUM_IPOD_POS) {
                    _currentUSBDeviceType = USB_IPHONE;
                }
                else if (i < NUM_IPAD_POS)
                {
                    _currentUSBDeviceType = USB_IPOD;
                }
                else
                {
                    _currentUSBDeviceType = USB_IPAD;
                }
                
                break;
            }
        }
    }
}

@end
