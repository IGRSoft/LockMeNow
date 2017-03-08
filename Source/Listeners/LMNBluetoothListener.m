//
//  LMNBluetoothListener.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import "LMNBluetoothListener.h"

#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

@interface LMNBluetoothListener ()

@property (nonatomic) NSOperationQueue	*queue;
@property (nonatomic) NSOperationQueue	*guiQueue;

//Bluetooth
@property (nonatomic) NSInteger	bluetoothTimerInterval;
@property (nonatomic) BluetoothStatus	bluetoothDevicePriorStatus;
@property (nonatomic) NSTimer			*bluetoothTimer;
@property (nonatomic, copy  ) NSString *bluetoothName;

@property (nonatomic) IOBluetoothDevice	*bluetoothDevice;

@end

@implementation LMNBluetoothListener

- (instancetype)initWithSettings:(IGRUserDefaults *)aSettings
{
    if (self = [super initWithSettings:aSettings])
    {
        _bluetoothDevicePriorStatus = NoneRange;
        _bluetoothDevice = nil;
        if (self.userSettings.bluetoothData)
        {
            _bluetoothDevice = [NSKeyedUnarchiver unarchiveObjectWithData:self.userSettings.bluetoothData];
        }
        [self updateDeviceName];
        
        _bluetoothTimerInterval = 2;
        
        _guiQueue = [[NSOperationQueue alloc] init];
        _queue = [[NSOperationQueue alloc] init];
        
        if (self.userSettings.bMonitoringBluetooth)
        {
            [self startListen];
        }
    }
    
    return self;
}

- (void)startListen
{
    if (![_bluetoothDevice isConnected])
    {
        IOReturn rt = [_bluetoothDevice openConnection:self];
        [self reset];
        if (rt != kIOReturnSuccess)
        {
            DBNSLog(@"Can't connect bluetoth device");
        }
    }
    
    _bluetoothTimer = [NSTimer scheduledTimerWithTimeInterval:self.bluetoothTimerInterval
                                                       target:self
                                                     selector:@selector(handleTimer:)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)stopListen
{
    [self reset];
    
    [_bluetoothDevice closeConnection];
    [_bluetoothTimer invalidate];
    
    [_queue cancelAllOperations];
    [_guiQueue cancelAllOperations];
    
    [[NSOperationQueue mainQueue] cancelAllOperations];
}

- (void)reset
{
    self.bluetoothDevicePriorStatus = NoneRange;
}

- (void)changeDevice
{
    IOBluetoothDeviceSelectorController *deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
    [deviceSelector runModal];
    
    NSArray *results = [deviceSelector getResults];
    
    if( !results )
    {
        return;
    }
    
    _bluetoothDevice = [results firstObject];
    _bluetoothDevicePriorStatus = NoneRange;
    
    NSData *deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:_bluetoothDevice];
    [self.userSettings saveUserSettingsWithBluetoothData:deviceAsData];
    
    [self updateDeviceName];
}

- (void)updateDeviceName
{
    if (_bluetoothDevice)
    {
        self.bluetoothName = [_bluetoothDevice name];
    }
}

- (BOOL)isInRange
{
    if (_bluetoothDevice)
    {
        if ([_bluetoothDevice remoteNameRequest:nil] == kIOReturnSuccess )
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)handleTimer:(NSTimer *)theTimer
{
    if (![[_queue operations] count])
    {
        [_queue addOperationWithBlock:^ {
            
            BOOL result = [self isInRange];
            
            if (_bluetoothDevicePriorStatus == NoneRange && self.bluetoothDevice)
            {
                self.bluetoothDevicePriorStatus = result ? InRange : OutOfRange;
            }
            
            if (result)
            {
                if (_bluetoothDevicePriorStatus == OutOfRange)
                {
                    [self makeUnlockAction:self];
                }
                self.bluetoothDevicePriorStatus = InRange;
            }
            else
            {
                if (_bluetoothDevicePriorStatus == InRange)
                {
                    [self makeLockAction:self];
                }
                
                self.bluetoothDevicePriorStatus = OutOfRange;
            }
        }];
    }
}

- (void)setBluetoothDevicePriorStatus:(BluetoothStatus)bluetoothDevicePriorStatus
{
    if (_bluetoothDevicePriorStatus == bluetoothDevicePriorStatus)
    {
        return;
    }
    
    _bluetoothDevicePriorStatus = bluetoothDevicePriorStatus;
    
    if (self.bluetoothStatusChangedBlock)
    {
        self.bluetoothStatusChangedBlock(_bluetoothDevicePriorStatus);
    }
}

@end
