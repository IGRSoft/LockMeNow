//
//  LockManager.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "LockManager.h"
#import "IGRUserDefaults.h"

@implementation LockManager

- (id)initWithConnection:(xpc_connection_t)aConnection settings:(IGRUserDefaults *)aSettings
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
}

- (void)unlock
{
	DBNSLog(@"%s Lock", __func__);
	
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

@end
