//
//  LMNJustLock.m
//  LockMeNow
//
//  Created by Vitalii Parovishnyk on 1/22/15.
//
//

#import "LMNJustLock.h"
#import "XPCScriptingProtocol.h"

static NSString * const kScreensaverDidStart = @"com.apple.screensaver.didstart";
static NSString * const kScreensaverDidStop = @"com.apple.screensaver.didstop";

@implementation LMNJustLock

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
	
    if (self.isLocked)
    {
        NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"startCurrentScreensaver" ofType:@"scpt"];
        
        [[self.scriptServiceConnection remoteObjectProxy] makeJustLock:self.userSettings.bUseCurrentScreenSaver
                                                            scriptPath:scriptPath];
        
        NSDistributedNotificationCenter* distCenter = [NSDistributedNotificationCenter defaultCenter];
        [distCenter addObserver:self
                       selector:@selector(screensaverStart:)
                           name:kScreensaverDidStart
                         object:nil];
        
        [distCenter addObserver:self
                       selector:@selector(screensaverStop:)
                           name:kScreensaverDidStop
                         object:nil];
    }
}

- (void)unlockByLockManager:(BOOL)byManager
{
    [super unlockByLockManager:byManager];
    
    [[self.scriptServiceConnection remoteObjectProxy] makeJustUnLock];
    
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self
                                                               name:kScreensaverDidStart
                                                             object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self
                                                               name:kScreensaverDidStop
                                                             object:nil];
}

- (void)screensaverStart:(NSNotification *)aNotification
{
    DBNSLog(@"Screensaver Start");
}

- (void)screensaverStop:(NSNotification *)aNotification
{
    DBNSLog(@"Screensaver Stop");
}

@end
