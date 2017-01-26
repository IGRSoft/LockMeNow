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
@property (nonatomic, strong) NSXPCConnection *preferencesServiceConnection;

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
        
        _preferencesServiceConnection = [[NSXPCConnection alloc] initWithServiceName:XPC_PREFERENCES];
        _preferencesServiceConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCPreferencesProtocol)];
        [_preferencesServiceConnection resume];
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
            
            [weakSelf unlock];
        }];
    }
    
    _isLocked = correctSettings;
}

- (void)unlock
{
	DBNSLog(@"%s UnLock", __func__);
	
    _isLocked = NO;
    
	[self.delegate unLockSuccess];
    
    [self setSecuritySetings:NO];
    
    if (_useSecurity)
    {
        [self stopCheckIncorrectPassword];
		[self stopCheckPowerMode];
    }
}

- (BOOL)askPassword
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL isPassword = NO;
    [[self.preferencesServiceConnection remoteObjectProxy] preferencesAskPassword:^(BOOL replay) {
        isPassword = replay;
        
        dispatch_semaphore_signal(semaphore);
    }];
	
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
	return isPassword;
}

- (NSNumber *)passwordDelay
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block NSNumber *passwordDelay = @0;
    [[self.preferencesServiceConnection remoteObjectProxy] preferencesPasswordDelay:^(NSNumber * replay) {
        passwordDelay = replay;
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return passwordDelay;
}

- (BOOL)setSecuritySetings:(BOOL)aLock
{
	if (aLock)
	{
        DBNSLog(@"Set Security Lock");
        
        _userUsePassword = [self askPassword];
        _passwordDelay = [self passwordDelay];
        
        if (!_userUsePassword || ![_passwordDelay isEqualToNumber:@0])
        {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"You chould enable a Require Password";
            alert.informativeText = @"Please, open General tab\nand enable \"Require Password\" (immediately) \nin System Preferences -> Security & Privacy.";
            
            [alert runModal];
            
            NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?General"];
            [[NSWorkspace sharedWorkspace] openURL:url];
        }
	}
    else
    {
        DBNSLog(@"Remove Security Lock");
    }
    
    return (_userUsePassword && [_passwordDelay isEqualToNumber:@0]);
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
                
                [weakSelf.delegate detectedWrongLoginAction];
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
				
				[weakSelf.delegate detectedWrongLoginAction];
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
