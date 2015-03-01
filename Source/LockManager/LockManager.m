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

@interface LockManager ()

@property (nonatomic, strong) NSXPCConnection *connectionToService;
@property (nonatomic, strong) FoudWrongPasswordBlock foudWrongPasswordBlock;

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
	}
	
	return self;
}

- (void)lock
{
    DBNSLog(@"%s Lock", __func__);
	
	if (!_useSecurity)
	{
		return;
	}
    
    [self setSecuritySetings:YES];
    [self startCheckIncorrectPassword];
}

- (void)unlock
{
	DBNSLog(@"%s UnLock", __func__);
	
	if ([self.delegate respondsToSelector:@selector(unLockSuccess)])
	{
		[self.delegate unLockSuccess];
	}
    
    if (!_useSecurity)
    {
        return;
    }
    
	[self setSecuritySetings:NO];
    [self stopCheckIncorrectPassword];
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
        _connectionToService = [[NSXPCConnection alloc] initWithServiceName:XPC_LOGER];
        _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCLogerProtocol)];
        [_connectionToService resume];
        
        __weak typeof(self) weakSelf = self;
        
        self.foudWrongPasswordBlock = ^{
            
            if ([weakSelf.delegate respondsToSelector:@selector(detectedWrongPassword)])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [weakSelf.delegate detectedWrongPassword];
                });
            }
            
            //Need update replay block, it called one times
            [[weakSelf.connectionToService remoteObjectProxy] updateReplayBlock:weakSelf.foudWrongPasswordBlock];
        };
        
        [[_connectionToService remoteObjectProxy] startCheckIncorrectPassword:self.foudWrongPasswordBlock];
    }
}

- (void)stopCheckIncorrectPassword
{
    if (_userSettings.bMakePhotoOnIncorrectPasword || _userSettings.bSendMailOnIncorrectPasword)
    {
        self.foudWrongPasswordBlock = nil;
        [[_connectionToService remoteObjectProxy] stopCheckIncorrectPassword];
        [_connectionToService invalidate];
        _connectionToService = nil;
    }
}

@end
