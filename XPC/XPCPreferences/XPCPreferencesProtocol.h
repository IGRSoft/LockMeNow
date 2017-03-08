//
//  XPCPreferencesProtocol.h
//  XPCPreferences
//
//  Created by Vitalii Parovishnyk on 1/26/17.
//  Copyright © 2017 IGR Soft. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSeviceName             "com.apple.screensaver"

#define kAskForPassword         "askForPassword"
#define kAskForPasswordDelay    "askForPasswordDelay"

typedef void (^XPCPreferencesReplayBlock)(BOOL);
typedef void (^XPCPreferencesAskPasswordBlock)(BOOL);
typedef void (^XPCPreferencesPasswordDelayBlock)(NSNumber * __nonnull);

@protocol XPCPreferencesProtocol

- (void)preferencesAskPassword:(XPCPreferencesAskPasswordBlock __nonnull)replyBlock;
- (void)setPreferencesAskPassword:(BOOL)askPassword
                       replyBlock:(XPCPreferencesReplayBlock __nonnull)replyBlock;

- (void)preferencesPasswordDelay:(XPCPreferencesPasswordDelayBlock __nonnull)replyBlock;
- (void)setPreferencesPasswordDelay:(NSNumber * __nonnull)passwordDelay
                         replyBlock:(XPCPreferencesReplayBlock __nonnull)replyBlock;
    
@end

