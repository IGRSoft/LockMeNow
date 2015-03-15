//
//  LockManager.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "LockManager.h"
#import "IGRUserDefaults.h"
#import "XPCLogerProtocol.h"
#import "XPCScreenProtocol.h"

@interface LockManager ()

@property (nonatomic, strong) NSXPCConnection *logerServiceConnection;
@property (nonatomic, strong) FoudWrongPasswordBlock foudWrongPasswordBlock;

@property (nonatomic, strong) NSXPCConnection *screenServiceConnection;

@property (nonatomic, assign) BOOL userUsePassword;
@property (nonatomic, assign) NSNumber *passwordDelay;

- (void)setSecuritySetings:(BOOL)aLock;

@end

@implementation LockManager

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

        self.screenServiceConnection = [[NSXPCConnection alloc] initWithServiceName:XPC_SCREEN];
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
    
    _isLocked = YES;
    
	if (_useSecurity)
	{
        [self setSecuritySetings:YES];
        [self startCheckIncorrectPassword];
	}

    __weak typeof(self) weakSelf = self;
    [[self.screenServiceConnection remoteObjectProxy] startListenScreenUnlock:^{
        
        [weakSelf unlock];
    }];
}

- (void)unlock
{
	DBNSLog(@"%s UnLock", __func__);
	
    _isLocked = NO;
    
	if ([self.delegate respondsToSelector:@selector(unLockSuccess)])
	{
		[self.delegate unLockSuccess];
	}
    
    if (_useSecurity)
    {
        [self setSecuritySetings:NO];
        [self stopCheckIncorrectPassword];
    }
}

- (BOOL)askPassword
{
	BOOL isPassword = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR("askForPassword"),
                                                            CFSTR("com.apple.screensaver"),
                                                            nil);
	
	return isPassword;
}

- (NSNumber *)passwordDelay
{
    NSNumber *passwordDelay = @(CFPreferencesGetAppIntegerValue(CFSTR("askForPasswordDelay"),
                                                                CFSTR("com.apple.screensaver"),
                                                                nil));
    
    return passwordDelay;
}

- (void)setSecuritySetings:(BOOL)aLock
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
        DBNSLog(@"Remove Security Lock");
        
        askPasswordVal = @(_userUsePassword);
        passwordDelayVal = _passwordDelay;
    }
	
    if (!_userUsePassword)
    {
        CFPreferencesSetValue(CFSTR("askForPassword"), (__bridge CFPropertyListRef) askPasswordVal,
                              CFSTR("com.apple.screensaver"),
                              kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    }
    
    if (![_passwordDelay isEqualToNumber:@0])
    {
        CFPreferencesSetValue(CFSTR("askForPasswordDelay"), (__bridge CFPropertyListRef) passwordDelayVal,
                              CFSTR("com.apple.screensaver"),
                              kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    }
    
    BOOL success = CFPreferencesSynchronize(CFSTR("com.apple.screensaver"),
                                            kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    
    if (!success)
    {
        DBNSLog(@"Can't sync Prefs");
    }
    else
    {
        // Notify login process
        // not sure this does or why it must be called...anyone? (DBR)
        CFMessagePortRef port = CFMessagePortCreateRemote(NULL, CFSTR("com.apple.loginwindow.notify"));
        success = (CFMessagePortSendRequest(port, 500, 0, 0, 0, 0, 0) == kCFMessagePortSuccess);
        CFRelease(port);
        if (success)
        {
            DBNSLog(@"Can't start screensaver");
        }
    }
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
            
            if ([weakSelf.delegate respondsToSelector:@selector(detectedWrongPassword)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [weakSelf.delegate detectedWrongPassword];
                });
            }
            
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

@end
