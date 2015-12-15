//
//  XPCPower.h
//  XPCPower
//
//  Created by Vitalii Parovishnyk on 12/15/15.
//
//

#import <Foundation/Foundation.h>
#import "XPCPowerProtocol.h"

typedef NS_ENUM(NSUInteger, IGRPowerMode)
{
	IGRPowerMode_None = 0,
	IGRPowerMode_ACPower,
	IGRPowerMode_Battery
};

@interface XPCPower : NSObject <XPCPowerProtocol>

@end
