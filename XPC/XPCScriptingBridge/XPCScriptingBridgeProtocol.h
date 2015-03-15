//
//  XPCScriptingBridgeProtocol.h
//  XPCScriptingBridge
//
//  Created by Vitalii Parovishnyk on 3/3/15.
//
//

#import <Foundation/Foundation.h>

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@protocol XPCScriptingBridgeProtocol

#pragma mark - iTunes

- (void)isMusicPlaingWithReply:(void (^)(BOOL))reply;
- (void)isMusicPausedWithReply:(void (^)(BOOL))reply;
- (void)playPauseMusic;

#pragma mark - Mail

- (void)setupMailAddres:(NSString *)aMail userPhoto:(NSString *)photoPath;
- (void)sendDefaultMessageAddLocation:(NSString *)aLocation;

@end

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     _connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"XPCScriptingBridge"];
     _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(StringModifing)];
     [_connectionToService resume];

Once you have a connection to the service, you can use it like this:

     [[_connectionToService remoteObjectProxy] upperCaseString:@"hello" withReply:^(NSString *aString) {
         // We have received a response. Update our text field, but do it on the main thread.
         NSLog(@"Result string was: %@", aString);
     }];

 And, when you are finished with the service, clean up the connection like this:

     [_connectionToService invalidate];
*/
