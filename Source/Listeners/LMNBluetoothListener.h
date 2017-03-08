//
//  LMNBluetoothListener.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import "LMNListenerManager.h"

typedef NS_ENUM(NSUInteger, BluetoothStatus)
{
    NoneRange = 0,
    InRange = 1,
    OutOfRange
};

typedef void (^LMNBluetoothStatusChangedBlock)(BluetoothStatus bluetoothStatus);

@interface LMNBluetoothListener : LMNListenerManager

@property (nonatomic, copy) LMNBluetoothStatusChangedBlock bluetoothStatusChangedBlock;

- (void)changeDevice;

@end
