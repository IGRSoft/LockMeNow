//
//  XPCLoger.h
//  XPCLoger
//
//  Created by Vitalii Parovishnyk on 2/28/15.
//
//

#import <Foundation/Foundation.h>
#import "XPCLogerProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface XPCLoger : NSObject <XPCLogerProtocol>
@end
