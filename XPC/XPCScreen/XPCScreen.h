//
//  XPCScreen.h
//  XPCScreen
//
//  Created by Vitalii Parovishnyk on 3/1/15.
//
//

#import <Foundation/Foundation.h>
#import "XPCScreenProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface XPCScreen : NSObject <XPCScreenProtocol>
@end
