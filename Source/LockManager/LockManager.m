//
//  LockManager.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "LockManager.h"
#import "IGRUserDefaults.h"

@interface LockManager ()

@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) NSString *lastLine;

@property (nonatomic, assign) BOOL userUsePassword;
@property (nonatomic, assign) NSNumber *passwordDelay;

- (void)setSecuritySetings:(BOOL)seter;

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

- (void)setSecuritySetings:(BOOL)askPassword
{
    NSNumber *askPasswordVal = @YES;
    NSNumber *passwordDelayVal = @0;
    
	if (askPassword)
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
        self.lastLine = nil;
        
        NSURL *filePath = [NSURL URLWithString:LOG_PATH];
        NSError *error = nil;
        
        self.fileHandle = [NSFileHandle fileHandleForReadingFromURL:filePath error:&error];
        
        if (!error)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleChannelDataAvailable:)
                                                         name:NSFileHandleDataAvailableNotification
                                                       object:self.fileHandle];
            
            [self.fileHandle waitForDataInBackgroundAndNotify];
        }
    }
}

- (void)stopCheckIncorrectPassword
{
    if (_userSettings.bMakePhotoOnIncorrectPasword || _userSettings.bSendMailOnIncorrectPasword)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSFileHandleDataAvailableNotification
                                                      object:self.fileHandle];
        
        self.fileHandle = nil;
        self.lastLine = nil;
    }
}

- (void)handleChannelDataAvailable:(NSNotification*)notification
{
    NSFileHandle *fileHandle = notification.object;
    
    NSString *str = [[NSString alloc] initWithData:fileHandle.availableData
                                          encoding:NSUTF8StringEncoding];
    
    NSString *contentForSearch = @"";
    
    BOOL skipCheck = NO;
    if (!self.lastLine)
    {
        self.lastLine = [str copy];
        skipCheck = YES;
    }
    
    NSRange newChunkRange = [str rangeOfString:self.lastLine];
    
    if (newChunkRange.location != NSNotFound)
    {
        contentForSearch = [str substringFromIndex:newChunkRange.location + newChunkRange.length - 1];
    }
    else
    {
        contentForSearch = [str copy];
    }
    
    if (!skipCheck)
    {
        NSRange range = [contentForSearch rangeOfString:@"OpenDirectory - The authtok is incorrect."];
        if (range.location != NSNotFound)
        {
            if ([self.delegate respondsToSelector:@selector(detectedWrongPassword)])
            {
                [self.delegate detectedWrongPassword];
            }
        }
    }
    
    NSArray *components = [str componentsSeparatedByString: @"\n"];
    
    if (components.count)
    {
        self.lastLine = components[components.count - 2];
    }
    
    [fileHandle waitForDataInBackgroundAndNotify];
}

@end
