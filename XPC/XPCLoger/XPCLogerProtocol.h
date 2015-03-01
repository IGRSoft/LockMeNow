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

- (void)startCheckIncorrectPassword:(FoudWrongPasswordBlock)replyBlock;
- (void)stopCheckIncorrectPassword;
- (void)updateReplayBlock:(FoudWrongPasswordBlock)replyBlock;
    
@end
