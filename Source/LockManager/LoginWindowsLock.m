//
//  LoginWindowsLock.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "LoginWindowsLock.h"
#import "IGRUserDefaults.h"
#import "XPCSriptingProtocol.h"

@implementation LoginWindowsLock

- (instancetype)initWithConnection:(NSXPCConnection *)aConnection settings:(IGRUserDefaults *)aSettings
{
	if (self = [super initWithConnection:aConnection settings:aSettings])
	{
	}
	
	return self;
}

- (void)lock
{
	[super lock];
	
	NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notificationCenter addObserver:self
						   selector:@selector(receiveBecomeActiveNotification:)
							   name:NSWorkspaceSessionDidBecomeActiveNotification
							 object:NULL];
	[notificationCenter addObserver:self
						   selector:@selector(receiveResignActiveNotification:)
							   name:NSWorkspaceSessionDidResignActiveNotification
							 object:NULL];
	
#if (1)
	[[NSTask launchedTaskWithLaunchPath:@"/bin/bash"
							  arguments:@[@"-c", @"exec \"/System/Library/CoreServices/Menu Extras/user.menu/Contents/Resources/CGSession\" -suspend"]]
	 waitUntilExit];
#else
	[[self.scriptServiceConnection remoteObjectProxy] makeLoginWindowLock];
#endif
}

- (void)unlock
{
	[super unlock];
}

#pragma mark - NSNotificationCenter

- (void)receiveBecomeActiveNotification:(NSNotification *)aNotification
{
	DBNSLog(@"Logo in");
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	
	[self unlock];
}

- (void)receiveResignActiveNotification:(NSNotification *)aNotification
{
	DBNSLog(@"Logo out");
}

@end
