//
//  JustLock.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "JustLock.h"
#import "IGRUserDefaults.h"
#import "XPCScriptingProtocol.h"

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
	
    [[self.scriptServiceConnection remoteObjectProxy] makeJustLock:self.userSettings.bUseCurrentScreenSaver];
}

- (void)unlock
{
	[super unlock];
}

@end
