//
//  LoginWindowsLock.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "LoginWindowsLock.h"
#import "IGRUserDefaults.h"

@implementation LoginWindowsLock

- (instancetype)initWithConnection:(xpc_connection_t)aConnection settings:(IGRUserDefaults *)aSettings
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
	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
	assert(message != NULL);
	
	xpc_dictionary_set_uint64(message, "locktype", LOCK_LOGIN_WINDOW);
	
	xpc_connection_send_message_with_reply(self.scriptServiceConnection, message,
										   dispatch_get_main_queue(), ^(xpc_object_t event) {
											   
											   DBNSLog(@"LOCK_LOGIN_WINDOW");
										   });
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
