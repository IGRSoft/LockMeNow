//
//  LMNKeyListener.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/27/15.
//
//

#import "LMNKeyListener.h"

#import <ShortcutRecorder/SRRecorderControl.h>
#import <PTHotKey/PTHotKeyCenter.h>
#import <PTHotKey/PTHotKey.h>

extern NSString *kGlobalHotKey;

@interface LMNKeyListener () <SRRecorderDelegate>

@property (nonatomic, strong) IBOutlet SRRecorderControl	*hotKeyControl;
@property (nonatomic, strong) PTHotKey						*hotKey;

@end

@implementation LMNKeyListener

- (instancetype)initWithSettings:(IGRUserDefaults *)aSettings
{
    if (self = [super initWithSettings:aSettings])
    {
        [self startListen];
    }
    
    return self;
}

- (void)startListen
{
    [self.hotKeyControl setCanCaptureGlobalHotKeys:YES];
    
    [[PTHotKeyCenter sharedCenter] unregisterHotKey:self.hotKey];
    PTKeyCombo *keyCombo = [[PTKeyCombo alloc] initWithPlistRepresentation:self.userSettings.keyCombo];
    
    self.hotKey = [[PTHotKey alloc] initWithIdentifier:kGlobalHotKey
                                              keyCombo:keyCombo];
    
    [self.hotKey setTarget: self];
    [self.hotKey setAction: @selector(makeLockAction:)];
    
    [[PTHotKeyCenter sharedCenter] registerHotKey:self.hotKey];
    
    NSNumber *kc = @(self.hotKey.keyCombo.keyCode);
    NSNumber *mf = @(self.hotKey.keyCombo.modifierMask);
    
    [self.hotKeyControl setObjectValue:@{@"keyCode": kc, @"modifierFlags": mf}];
}

- (void)stopListen
{
    
}

- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
    return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    PTKeyCombo *keyCombo = [PTKeyCombo keyComboWithKeyCode:[aRecorder keyCombo].code
                                                 modifiers:[aRecorder cocoaToCarbonFlags:[aRecorder keyCombo].flags]];
    
    if (aRecorder == self.hotKeyControl)
    {
        self.hotKey.keyCombo = keyCombo;
        
        // Re-register the new hot key
        [[PTHotKeyCenter sharedCenter] registerHotKey:self.hotKey];
        self.userSettings.keyCombo = [keyCombo plistRepresentation];
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf.userSettings saveUserSettingsWithBluetoothData:nil];
        });
    }
}

@end
