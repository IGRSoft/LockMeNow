//
//  XPCPreferences.m
//  XPCPreferences
//
//  Created by Vitalii Parovishnyk on 1/26/17.
//  Copyright © 2017 IGR Soft. All rights reserved.
//

#import "XPCPreferences.h"
#import <CoreFoundation/CoreFoundation.h>

@implementation XPCPreferences

- (void)preferencesAskPassword:(XPCPreferencesAskPasswordBlock __nonnull)replyBlock
{
    BOOL isPassword = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR(kAskForPassword),
                                                            CFSTR(kSeviceName),
                                                            nil);
    
    replyBlock(isPassword);
}

- (void)setPreferencesAskPassword:(BOOL)askPassword replyBlock:(XPCPreferencesReplayBlock __nonnull)replyBlock
{
    CFPreferencesSetValue(CFSTR(kAskForPassword), (__bridge CFPropertyListRef) @(askPassword),
                          CFSTR(kSeviceName),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    BOOL success = CFPreferencesSynchronize(CFSTR(kSeviceName), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    replyBlock(success);
}

- (void)preferencesPasswordDelay:(XPCPreferencesPasswordDelayBlock __nonnull)replyBlock
{
    NSNumber *passwordDelay = @(CFPreferencesGetAppIntegerValue(CFSTR(kAskForPasswordDelay),
                                                                CFSTR(kSeviceName),
                                                                nil));
    
    replyBlock(passwordDelay);
}

- (void)setPreferencesPasswordDelay:(NSNumber *)passwordDelay replyBlock:(XPCPreferencesReplayBlock __nonnull)replyBlock
{
    CFPreferencesSetValue(CFSTR(kAskForPasswordDelay), (__bridge CFPropertyListRef) passwordDelay,
                          CFSTR(kSeviceName),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    BOOL success = CFPreferencesSynchronize(CFSTR(kSeviceName), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    replyBlock(success);
}

@end
