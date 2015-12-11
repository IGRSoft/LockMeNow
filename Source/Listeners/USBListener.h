//
//  USBListener.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import "ListenerManager.h"

#define NUM_APPLE_MOBILE_DEVICES	22

#define NUM_IPHONE_POS	0
#define NUM_IPOD_POS	8
#define NUM_IPAD_POS	13

#define VENDOR_APPLE	0x05ac

typedef struct {
    const char *name;
    uint16_t productID;
} APPLE_MOBILE_DEVICE;

@interface USBListener : ListenerManager

@end
