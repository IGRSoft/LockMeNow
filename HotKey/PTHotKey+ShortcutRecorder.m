//
//  PTHotKey+ShortcutRecorder.m
//  ShortcutRecorder
//
//  Created by Ilya Kulakov on 27.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "PTHotKey+ShortcutRecorder.h"
#import <ShortcutRecorder/SRCommon.h>
#import "PTKeyCombo.h"

extern NSString* const SRShortcutCodeKey;
extern NSString* const SRShortcutFlagsKey;

@implementation PTHotKey (ShortcutRecorder)

+ (PTHotKey *)hotKeyWithIdentifier:(id)anIdentifier
                          keyCombo:(NSDictionary *)aKeyCombo
                            target:(id)aTarget
                            action:(SEL)anAction
{
    NSInteger keyCode = [aKeyCombo[SRShortcutCodeKey] integerValue];
    NSUInteger modifiers = SRCocoaToCarbonFlags([aKeyCombo[SRShortcutFlagsKey] unsignedIntegerValue]);
    PTKeyCombo *newKeyCombo = [[PTKeyCombo alloc] initWithKeyCode:keyCode modifiers:modifiers];
    PTHotKey *newHotKey = [[PTHotKey alloc] initWithIdentifier:anIdentifier keyCombo:newKeyCombo];
    [newHotKey setTarget:aTarget];
    [newHotKey setAction:anAction];
    return newHotKey;
}

@end
