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
    InRange = 0,
    OutOfRange
};

typedef void (^LMNBluetoothStatusChangedBlock)(BluetoothStatus bluetoothStatus);

@interface LMNBluetoothListener : LMNListenerManager

@property (nonatomic, copy  ) NSString *bluetoothName;
@property (nonatomic, assign) BOOL checkingInProgress;

@property (nonatomic, copy) LMNBluetoothStatusChangedBlock bluetoothStatusChangedBlock;

- (void)changeDevice;

@end
