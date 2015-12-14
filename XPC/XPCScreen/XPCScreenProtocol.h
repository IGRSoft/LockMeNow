//
//  XPCScreenProtocol.h
//  XPCScreen
//
//  Created by Vitalii Parovishnyk on 3/1/15.
//
//

#import <Foundation/Foundation.h>

typedef void (^DetectedUnlockBlock)(void);

@protocol XPCScreenProtocol

- (void)startListenScreenUnlock:(DetectedUnlockBlock __nonnull)reply;
- (void)stopListenScreenUnlock;

@end
