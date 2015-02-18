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
@end

@implementation LockManager

- (instancetype)initWithConnection:(xpc_connection_t)aConnection settings:(IGRUserDefaults *)aSettings
{
	if (self = [super init])
	{
		_scriptServiceConnection = aConnection;
		_userSettings = aSettings;
		_useSecurity = NO;
		_allowTerminate = YES;
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
	
	BOOL m_bNeedBlock = ![self askPassword];
	
	if (m_bNeedBlock)
	{
		DBNSLog(@"Set Security Lock");
		[self setSecuritySetings:YES withSkip:m_bNeedBlock];
	}
    
    [self startCheckIncorrectPassword];
}

- (void)unlock
{
	DBNSLog(@"%s UnLock", __func__);
	
	if ([self.delegate respondsToSelector:@selector(unLockSuccess)])
	{
		[self.delegate unLockSuccess];
	}
	
	BOOL m_bNeedBlock = ![self askPassword];
	
	if (m_bNeedBlock)
	{
		DBNSLog(@"Remove Security Lock");
		[self setSecuritySetings:NO withSkip:m_bNeedBlock];
	}
    
    [self stopCheckIncorrectPassword];
}

- (BOOL)askPassword
{
	
	BOOL isPassword = NO;
	
	if (!_userSettings.bEncription)
	{
		isPassword = (BOOL)CFPreferencesGetAppBooleanValue(CFSTR("askForPassword"), CFSTR("com.apple.screensaver"), nil);
	}
	
	return isPassword;
}

- (void)setSecuritySetings:(BOOL)seter withSkip:(BOOL)skip
{
	if (!_userSettings.bAutoPrefs)
	{
		return;
	}
	
	BOOL success = YES;
	
	if (!skip)
	{
		NSNumber *val = @(seter);
		CFPreferencesSetValue(CFSTR("askForPassword"), (__bridge CFPropertyListRef) val,
							  CFSTR("com.apple.screensaver"),
							  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		success = CFPreferencesSynchronize(CFSTR("com.apple.screensaver"),
										   kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		
		if (success)
		{
			DBNSLog(@"Can't sync Prefs");
		}
		
		CFPreferencesSetValue(CFSTR("askForPasswordDelay"), (__bridge CFPropertyListRef) @0,
							  CFSTR("com.apple.screensaver"),
							  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		success = CFPreferencesSynchronize(CFSTR("com.apple.screensaver"),
										   kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		
		// Notify login process
		// not sure this does or why it must be called...anyone? (DBR)
		if (success)
		{
			CFMessagePortRef port = CFMessagePortCreateRemote(NULL, CFSTR("com.apple.loginwindow.notify"));
			success = (CFMessagePortSendRequest(port, 500, 0, 0, 0, 0, 0) == kCFMessagePortSuccess);
			CFRelease(port);
			if (success)
			{
				DBNSLog(@"Can't start screensaver");
			}
		}
	}
}

- (void)startCheckIncorrectPassword
{
    if (!_userSettings.bMakePhotoOnIncorrectPasword)
    {
        return;
    }
    
    self.lastLine = nil;
    
    NSURL *filePath = [NSURL URLWithString:@"/private/var/log/lockmenow.log"];
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

- (void)stopCheckIncorrectPassword
{
    if (!_userSettings.bMakePhotoOnIncorrectPasword)
    {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                     name:NSFileHandleDataAvailableNotification
                                                   object:self.fileHandle];
    
    self.fileHandle = nil;
    self.lastLine = nil;
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
