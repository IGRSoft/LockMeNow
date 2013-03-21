//
//  ScriptHelper.h
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 2/13/13.
//
//

#import <Foundation/Foundation.h>

@protocol ScriptAgent

- (void)checkEncription:(void (^)(bool encription))reply;
- (void)makeLoginWindowLock;

@end

// The Zipper singleton is both the exported object for the zip-service and the NSXPCListenerDelegate, responsible for configuring incoming connections.
@interface ScriptServer : NSObject <ScriptAgent, NSXPCListenerDelegate>

+ (ScriptServer *)sharedScriptServer;

@end
