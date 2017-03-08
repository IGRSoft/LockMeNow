//
//  LMNLockManager.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "LMNLockManager.h"
#import "XPCLogerProtocol.h"
#import "XPCScreenProtocol.h"
#import "XPCPowerProtocol.h"
#import "XPCPreferences.h"

@interface LMNLockManager ()

@property (nonatomic, strong) NSXPCConnection *logerServiceConnection;
@property (nonatomic, strong) FoudWrongPasswordBlock foudWrongPasswordBlock;

@property (nonatomic, strong) NSXPCConnection *screenServiceConnection;

@property (nonatomic, strong) NSXPCConnection *powerServiceConnection;
@property (nonatomic, strong) FoudChangesInPowerBlock foudChangesInPowerBlock;

@property (nonatomic, assign) BOOL userUsePassword;
@property (nonatomic, assign) NSNumber *passwordDelay;

- (BOOL)setSecuritySetings:(BOOL)aLock;

@end

@implementation LMNLockManager

- (instancetype)initWithConnection:(NSXPCConnection *)aConnection settings:(IGRUserDefaults *)aSettings
{
	if (self = [super init])
	{
		_scriptServiceConnection = aConnection;
		_userSettings = aSettings;
		_useSecurity = NO;
		_allowTerminate = YES;
        
        _userUsePassword = NO;
        _passwordDelay = @0;
        _isLocked = NO;

        _screenServiceConnection = [[NSXPCConnection alloc] initWithServiceName:XPC_SCREEN];
        _screenServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCScreenProtocol)];
        [_screenServiceConnection resume];
	}
	
	return self;
}

- (void)dealloc
{
    [_screenServiceConnection invalidate];
}

- (void)lock
{
    DBNSLog(@"%s Lock", __func__);
    
    BOOL correctSettings = [self setSecuritySetings:YES];
    
    if (correctSettings) {
        if (_useSecurity)
        {
            [self startCheckIncorrectPassword];
            [self startCheckPowerMode];
        }
        
        __weak typeof(self) weakSelf = self;
        [[self.screenServiceConnection remoteObjectProxy] startListenScreenUnlock:^{
            
            [weakSelf unlockByLockManager:NO];
        }];
    }
    
    _isLocked = correctSettings;
}

- (void)unlockByLockManager:(BOOL)byManager
{
	DBNSLog(@"%s UnLock", __func__);
	
    _isLocked = NO;
    
	[self.delegate unLockSuccess];
    
    if (byManager) {
        [self unlockSecuritySetings];
    }
    else
    {
        [self setSecuritySetings:NO];
    }
    
    if (_useSecurity)
    {
        [self stopCheckIncorrectPassword];
		[self stopCheckPowerMode];
    }
}

- (BOOL)askPassword
{
    BOOL isPassword = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR(kAskForPassword),
                                                            CFSTR(kSeviceName),
                                                            nil);
    
	return isPassword;
}

- (NSNumber *)passwordDelay
{
    NSNumber *passwordDelay = @(CFPreferencesGetAppIntegerValue(CFSTR(kAskForPasswordDelay),
                                                                CFSTR(kSeviceName),
                                                                nil));
    
    return passwordDelay;
}

- (BOOL)unlockSecuritySetings
{
    DBNSLog(@"Remove Security Lock by Lock Manager");
    
    NSNumber *askPasswordVal = @NO;
    NSNumber *passwordDelayVal = @0;
    
    CFPreferencesSetValue(CFSTR(kAskForPassword), (__bridge CFPropertyListRef) askPasswordVal,
                          CFSTR(kSeviceName),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    CFPreferencesSetValue(CFSTR(kSeviceName), (__bridge CFPropertyListRef) passwordDelayVal,
                          CFSTR(kAskForPasswordDelay),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    BOOL success = CFPreferencesSynchronize(CFSTR(kSeviceName),
                                            kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    if (!success)
    {
        DBNSLog(@"Can't sync Prefs");
    }
    
    sleep(1); //Need wait 1
    
    return success;
}

- (BOOL)setSecuritySetings:(BOOL)aLock
{
    NSNumber *askPasswordVal = @YES;
    NSNumber *passwordDelayVal = @0;
    
    if (aLock)
    {
        DBNSLog(@"Set Security Lock");
        
        _userUsePassword = [self askPassword];
        _passwordDelay = [self passwordDelay];
    }
    else
    {
        sleep(1); //Need wait 1
        DBNSLog(@"Remove Security Lock by Listener");
        
        askPasswordVal = @(_userUsePassword);
        passwordDelayVal = _passwordDelay;
    }
    
    CFPreferencesSetValue(CFSTR(kAskForPassword), (__bridge CFPropertyListRef) askPasswordVal,
                          CFSTR(kSeviceName),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    CFPreferencesSetValue(CFSTR(kAskForPasswordDelay), (__bridge CFPropertyListRef) passwordDelayVal,
                          CFSTR(kSeviceName),
                          kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    BOOL success = CFPreferencesSynchronize(CFSTR(kSeviceName),
                                            kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    if (!success)
    {
        DBNSLog(@"Can't sync Prefs");
    }
    
    return success;
}

- (void)startCheckIncorrectPassword
{
    if (_userSettings.bMakePhotoOnIncorrectPasword || _userSettings.bSendMailOnIncorrectPasword)
    {
        self.logerServiceConnection = [[NSXPCConnection alloc] initWithServiceName:XPC_LOGER];
        _logerServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCLogerProtocol)];
        [_logerServiceConnection resume];
        
        __weak typeof(self) weakSelf = self;
        
        self.foudWrongPasswordBlock = ^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [weakSelf.delegate detectedEnterPassword];
            });
            
            //Need update replay block, it called one times
            [[weakSelf.logerServiceConnection remoteObjectProxy] updateReplayBlock:weakSelf.foudWrongPasswordBlock];
        };
        
        [[_logerServiceConnection remoteObjectProxy] startCheckIncorrectPassword:self.foudWrongPasswordBlock];
    }
}

- (void)stopCheckIncorrectPassword
{
    if (_userSettings.bMakePhotoOnIncorrectPasword || _userSettings.bSendMailOnIncorrectPasword)
    {
        self.foudWrongPasswordBlock = nil;
        [[_logerServiceConnection remoteObjectProxy] stopCheckIncorrectPassword];
        [_logerServiceConnection invalidate];
    }
}

- (void)startCheckPowerMode
{
	if (_userSettings.bControllMagSafe)
	{
		self.powerServiceConnection = [[NSXPCConnection alloc] initWithServiceName:XPC_POWER];
		_powerServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCPowerProtocol)];
		[_powerServiceConnection resume];
		
		__weak typeof(self) weakSelf = self;
		
		self.foudChangesInPowerBlock = ^{
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				[weakSelf.delegate detectedUnplygMagSafeAction];
			});
			
			//Need update replay block, it called one times
			[[weakSelf.powerServiceConnection remoteObjectProxy] updateReplayBlock:weakSelf.foudChangesInPowerBlock];
		};
		
		[[_powerServiceConnection remoteObjectProxy] startCheckPower:self.foudChangesInPowerBlock];
	}
}

- (void)stopCheckPowerMode
{
	if (_userSettings.bControllMagSafe)
	{
		self.foudWrongPasswordBlock = nil;
		[[_powerServiceConnection remoteObjectProxy] stopCheckPower];
		[_powerServiceConnection invalidate];
	}
}

@end
