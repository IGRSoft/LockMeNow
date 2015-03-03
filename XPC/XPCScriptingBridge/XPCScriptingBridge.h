//
//  XPCScriptingBridge.h
//  XPCScriptingBridge
//
//  Created by Vitalii Parovishnyk on 3/3/15.
//
//

#import <Foundation/Foundation.h>
#import "XPCScriptingBridgeProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface XPCScriptingBridge : NSObject <XPCScriptingBridgeProtocol>
@end
