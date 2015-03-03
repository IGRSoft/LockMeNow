//
//  XPCScriptingProtocol.h
//  XPCScripting
//
//  Created by Vitalii Parovishnyk on 2/27/15.
//
//

#import <Foundation/Foundation.h>

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@protocol XPCScriptingProtocol

/*- (NSString *)doShell:(NSString *)file;
- (void)checkEncriptionWithReply:(void (^)(BOOL))reply;*/

- (void)makeLoginWindowLock;
- (void)makeJustLock:(BOOL)useCurrentScrrenSaver;
    
@end
