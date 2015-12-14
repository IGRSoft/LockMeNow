//
//  XPCLogerProtocol.h
//  XPCLoger
//
//  Created by Vitalii Parovishnyk on 2/28/15.
//
//

#import <Foundation/Foundation.h>

typedef void (^FoudWrongPasswordBlock)(void);

@protocol XPCLogerProtocol

- (void)startCheckIncorrectPassword:(FoudWrongPasswordBlock __nonnull)replyBlock;
- (void)stopCheckIncorrectPassword;
- (void)updateReplayBlock:(FoudWrongPasswordBlock __nonnull)replyBlock;
    
@end
