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
    
    NSDistributedNotificationCenter* distCenter = [NSDistributedNotificationCenter defaultCenter];
    [distCenter addObserver:self
                   selector:@selector(screensaverStart:)
                       name:@"com.apple.screensaver.didstart"
                     object:nil];
    
    [distCenter addObserver:self
                   selector:@selector(screensaverStop:)
                       name:@"com.apple.screensaver.didstop"
                     object:nil];
}

- (void)unlock
{
	[super unlock];
    
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)screensaverStart:(NSNotification *)aNotification
{
    DBNSLog(@"Screensaver Start");
}

- (void)screensaverStop:(NSNotification *)aNotification
{
    DBNSLog(@"Screensaver Stop");
    
    [self.delegate userTryEnterPassword];
}

@end
