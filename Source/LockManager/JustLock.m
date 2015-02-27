//
//  JustLock.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "JustLock.h"
#import "IGRUserDefaults.h"
#import "XPCSriptingProtocol.h"

@implementation JustLock

- (instancetype)initWithConnection:(NSXPCConnection *)aConnection settings:(IGRUserDefaults *)aSettings
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
	
    [[self.scriptServiceConnection remoteObjectProxy] makeJustLock:self.userSettings.bUseCurrentScreenSaver];
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
