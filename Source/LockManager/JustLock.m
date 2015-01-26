//
//  JustLock.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "JustLock.h"
#import "IGRUserDefaults.h"

@implementation JustLock

- (id)initWithConnection:(xpc_connection_t)aConnection settings:(IGRUserDefaults *)aSettings
{
	if (self = [super initWithConnection:aConnection settings:aSettings])
	{
		self.useSecurity = YES;
	}
	
	return self;
}

- (void)lock
{
	[super lock];
	
	NSDistributedNotificationCenter* distCenter = [NSDistributedNotificationCenter defaultCenter];
	[distCenter addObserver:self
				   selector:@selector(setScreenLockActive:)
					   name:@"com.apple.screenIsLocked"
					 object:NULL];
	
	[distCenter addObserver:self
				   selector:@selector(setScreenLockInActive:)
					   name:@"com.apple.screenIsUnlocked"
					 object:NULL];
	
	[distCenter addObserver:self
				   selector:@selector(screensaverStartStop:)
					   name:@"com.apple.screensaver.didstart"
					 object:NULL];
	
	[distCenter addObserver:self
				   selector:@selector(screensaverStartStop:)
					   name:@"com.apple.screensaver.didstop"
					 object:NULL];
	
	xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
	assert(message != NULL);
	
	xpc_dictionary_set_uint64(message, "locktype", LOCK_SCREEN);
	xpc_dictionary_set_bool(message, "usecurrentscreensaver", self.userSettings.bUseCurrentScreenSaver);
	
	xpc_connection_send_message_with_reply(self.scriptServiceConnection, message,
										   dispatch_get_main_queue(), ^(xpc_object_t event) {
											   
										   });
}

- (void)unlock
{
	[super unlock];
	
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSDistributedNotificationCenter

- (void)setScreenLockActive:(NSNotification *)aNotification
{
	DBNSLog(@"Screen Lock");
}

- (void)setScreenLockInActive:(NSNotification *)aNotification
{
	DBNSLog(@"Screen Unlock");
	[self unlock];
}

- (void)screensaverStartStop:(NSNotification *)aNotification
{

}

@end
