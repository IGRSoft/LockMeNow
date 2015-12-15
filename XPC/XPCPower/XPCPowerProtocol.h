//
//  XPCPowerProtocol.h
//  XPCPower
//
//  Created by Vitalii Parovishnyk on 12/15/15.
//
//

#import <Foundation/Foundation.h>

typedef void (^FoudChangesInPowerBlock)(void);

@protocol XPCPowerProtocol

- (void)startCheckPower:(FoudChangesInPowerBlock __nonnull)replyBlock;
- (void)stopCheckPower;
- (void)updateReplayBlock:(FoudChangesInPowerBlock __nonnull)replyBlock;

@end
