//
//  XPCPreferences.h
//  XPCPreferences
//
//  Created by Vitalii Parovishnyk on 1/26/17.
//  Copyright © 2017 IGR Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCPreferencesProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface XPCPreferences : NSObject <XPCPreferencesProtocol>
@end
